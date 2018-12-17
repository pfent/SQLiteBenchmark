#include <iostream>
#include <sqlite3.h>
#include <memory>
#include <chrono>
#include "ycsb.h"
#include "util/doNotOptimize.h"
#include "util/Random32.h"

template<typename T>
auto bench(T &&fun) {
   const auto start = std::chrono::high_resolution_clock::now();

   fun();

   const auto end = std::chrono::high_resolution_clock::now();

   return std::chrono::duration<double>(end - start).count();
}


auto openSqlite() {
   sqlite3* sqlite = nullptr;
   auto res = sqlite3_open_v2(":memory:", &sqlite, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_NOMUTEX,
                              nullptr);
   auto resultPtr = std::unique_ptr<sqlite3, decltype(&sqlite3_close_v2)>(sqlite, &sqlite3_close_v2);
   if (res != SQLITE_OK) {
      throw std::runtime_error(std::string("Couldn't open connection: ") + sqlite3_errmsg(sqlite));
   }

   return resultPtr;
}

auto prepare(sqlite3* sqlite, const std::string &query) {
   sqlite3_stmt* statement = nullptr;
   auto res = sqlite3_prepare_v2(sqlite, query.c_str(), query.length(), &statement, nullptr);
   auto resultPtr = std::unique_ptr<sqlite3_stmt, decltype(&sqlite3_finalize)>(statement, &sqlite3_finalize);
   if (res != SQLITE_OK) {
      throw std::runtime_error(std::string("Couldn't prepare statement: ") + sqlite3_errmsg(sqlite));
   }
   return resultPtr;
}

auto execute(sqlite3_stmt* statement) {
   if (sqlite3_step(statement) != SQLITE_DONE) {
      throw std::runtime_error(std::string("attempted to execute invalid or multirow statement"));
   }
}

auto step(sqlite3* sqlite, sqlite3_stmt* statement) {
   auto res = sqlite3_step(statement);
   switch (res) {
      case SQLITE_DONE:
      case SQLITE_ROW:
         return res;
      default:
         throw std::runtime_error(std::string("Error in statement: ") + sqlite3_errmsg(sqlite));
   }
}

auto bindIntParameter(sqlite3* sqlite, sqlite3_stmt* statement, int index, int value) {
   if(sqlite3_bind_int(statement, index, value) != SQLITE_OK) {
      throw std::runtime_error(std::string("Error in bind parameter: ") + sqlite3_errmsg(sqlite));
   }
}

static auto db = YcsbDatabase();

void prepareYcsb(sqlite3* sqlite) {
   {
      auto create = std::string("CREATE TEMPORARY TABLE Ycsb ( ycsb_key INTEGER PRIMARY KEY NOT NULL, ");
      for (size_t i = 1; i < ycsb_field_count; ++i) {
         create += "v" + std::to_string(i) + " CHAR(" + std::to_string(ycsb_field_length) + ") NOT NULL, ";
      }
      create += "v" + std::to_string(ycsb_field_count) + " CHAR(" + std::to_string(ycsb_field_length) + ") NOT NULL";
      create += ");";

      auto createStatement = prepare(sqlite, create);
      execute(createStatement.get());
   }

   for (auto it = db.database.begin(); it != db.database.end();) {
      auto i = std::distance(db.database.begin(), it);
      if (i % (ycsb_tuple_count / 100) == 0) {
         std::cout << "\r" << static_cast<double>(i) * 100 / ycsb_tuple_count << "%" << std::flush;
      }
      auto statement = std::string("INSERT INTO Ycsb VALUES ");
      for (int j = 0; j < 1000; ++j, ++it) {
         auto&[key, value] = *it;
         statement += "(" + std::to_string(key) + ", ";
         for (auto &v : value.rows) {
            statement += "'";
            statement += v.data();
            statement += "', ";
         }
         statement.resize(statement.length() - 2); // remove last comma
         statement += "), ";
      }
      statement.resize(statement.length() - 2); // remove last comma
      statement += ";";

      auto insertStatement = prepare(sqlite, statement);
      execute(insertStatement.get());
   }
   std::cout << "\n";
}


void doSmallTx(sqlite3* sqlite) {
   auto rand = Random32();
   const auto lookupKeys = generateZipfLookupKeys(ycsb_tx_count);

   std::cout << "benchmarking " << lookupKeys.size() << " small transactions" << '\n';

   auto result = std::array<char, ycsb_field_length>();

   auto columnStatements = std::vector<decltype(prepare(sqlite, ""))>();
   for (size_t i = 1; i < ycsb_field_count + 1; ++i) {
      auto statement = std::string("SELECT v") + std::to_string(i) + " FROM Ycsb WHERE ycsb_key=?";
      columnStatements.push_back(prepare(sqlite, statement));
   }

   auto param = YcsbKey();

   auto timeTaken = bench([&] {
      for (auto lookupKey: lookupKeys) {
         auto which = rand.next() % ycsb_field_count;
         auto &statement = columnStatements[which];

         param = lookupKey;
         bindIntParameter(sqlite, statement.get(), 1, param);

         if (step(sqlite, statement.get()) != SQLITE_ROW) {
            throw std::runtime_error("expected a row returned");
         }

         auto res = sqlite3_column_text(statement.get(), 0);
         std::copy(res, &res[ycsb_field_length], result.data());

         auto expected = std::array<char, ycsb_field_length>();
         db.lookup(lookupKey, which, expected.begin());
         if (!std::equal(result.begin(), result.end(), expected.begin())) {
            throw std::runtime_error("unexpected result");
         }

         // should probably be handled by a unique_ptr
         sqlite3_reset(statement.get());
      }
   });

   std::cout << " " << lookupKeys.size() / timeTaken << " msg/s\n";
}

void doLargeResultSet(sqlite3* sqlite) {
   const auto resultSizeMB = static_cast<double>(ycsb_tuple_count) * ycsb_field_count * ycsb_field_length / 1024 / 1024;
   std::cout << "benchmarking " << resultSizeMB << "MB data transfer" << '\n';

   auto statement = prepare(sqlite, "SELECT v1,v2,v3,v4,v5,v6,v7,v8,v9,v10 FROM Ycsb");

   auto result = std::array<std::array<char, ycsb_field_length>, ycsb_field_count>();

   auto timeTaken = bench([&] {

      for (size_t i = 0; i < ycsb_tuple_count; ++i) {
         if (step(sqlite, statement.get()) != SQLITE_ROW) {
            throw std::runtime_error("expected more rows returned");
         }

         DoNotOptimize(result);
         for (size_t j = 0; j < ycsb_field_count; ++j) {
            auto res = sqlite3_column_text(statement.get(), static_cast<int>(j));
            std::copy(res, &res[ycsb_field_length], result[j].data());
         }
         ClobberMemory();
      }
   });

   std::cout << " " << resultSizeMB / timeTaken << " MB/s\n";
}


int main() {
   auto sqlite = openSqlite();

   try {
      std::cout << "Preparing YCSB temporary table\n";
      prepareYcsb(sqlite.get());

      doSmallTx(sqlite.get());
      doLargeResultSet(sqlite.get());
   } catch (const std::runtime_error &e) {
      std::cout << e.what() << '\n';
   }

   return 0;
}