//+------------------------------------------------------------------+
//|   MySQL.mqh
//|   Force_Majeure
//|   force_m@mail.ru
//+------------------------------------------------------------------+
// MySQL - Работа с базой данных MySQL
//+------------------------------------------------------------------+
#property copyright "Force_Majeure"
#property link      "force_m@mail.ru"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
#import "libmysql.dll"
int mysql_init(int Db);    // инициализация MySQL
void mysql_close(int Db);  // Дисконнект от БД
int mysql_errno(int Db);   // Код ошибки
int mysql_error(int Db);   // Текстовое описание ошибки
int mysql_real_connect(int Db, string host, string user, string password,string DB,int port,int socket,int clientflag);   // Коннект к БД
int mysql_real_query(int Db, string query, int length);  // Выполнение запроса
int mysql_store_result(int Db); // Доступ к резульататам запроса
void mysql_free_result(int Result); // Чистка результатов запроса
string mysql_fetch_row(int Result); // Получить очередную строку с резутатами запроса
int mysql_num_rows(int Result);     // Получить кол-во строк в результате запроса

//int mysql_num_fields(int Result);
//int mysql_fetch_lengths(int Result);

#import
//+------------------------------------------------------------------+
int MySQLDatabase;
string MySQLQuery;
string MySQLHost;
string MySQLUser;
string MySQLPassword;
string MySQLDb;
int MySQLClientflag;
int MySQLPort;
string MySQLSocket;
//+------------------------------------------------------------------+
//                            ФУНКЦИИ
//+------------------------------------------------------------------+
void MySQLInit() {
   // Конструктор
MySQLHost = "";
MySQLUser = "";
MySQLPassword = "";
MySQLDb = "";
MySQLClientflag = 0;
MySQLPort = 3306;
MySQLSocket = "";
return;
}
//+------------------------------------------------------------------+
void MySQLRelease() {
   // Деструктор
mysql_close(MySQLDatabase);
return;
}
//+------------------------------------------------------------------+
bool MySQLConnect() {
   // Подсоединение к базе данных
if(MySQLHost==""||MySQLUser==""||MySQLPassword==""||MySQLDb=="") return(false);
MySQLDatabase = mysql_init(MySQLDatabase);
int Res = mysql_real_connect(MySQLDatabase,MySQLHost,MySQLUser,MySQLPassword,MySQLDb,MySQLPort,MySQLSocket,MySQLClientflag);
int Err = GetLastError();
if(Res!=MySQLDatabase) {
   Print("Не установлено соединение c MySQL");
   return(false);
}
return(true);
}
//+------------------------------------------------------------------+
void MySQLUtfToAnsi() {
   // Включение преобразования кодировки "на лету" из UTF8 а ANSI1251
MySQLQuery = "SET CHARACTER SET cp1251_koi8;";
MySQLExec();
return;
}
//+------------------------------------------------------------------+
int MySQLExec() {
   // Выполнение запроса. Возвращает кол-во строк в результате запроса.
if(MySQLQuery=="") return(0);
int Length = StringLen(MySQLQuery);
mysql_real_query(MySQLDatabase,MySQLQuery,Length);
int Err = mysql_errno(MySQLDatabase);
if(Err>0) Print("Ошибка ",Err," ",mysql_error(MySQLDatabase));
   // нужен ли вывод резултатов
if(StringSubstr(MySQLQuery,0,6)=="select") {
   int Rez = mysql_store_result(MySQLDatabase);
   int NumRows = mysql_num_rows(Rez);

   // Вывод полученных значений - не решил проблему т.к. mysql_fetch_row возвращает специальный тип строки MYSQL_ROW
   // которая не явлеяется строкой с /0 в конце а mysql_num_fields возвращает указатель на массив а с указателями MQL4
   // не работает

// Если в таблице одно текстовое поле - его можно получить так:
//   string row;
//   for (int i=0;i<NumRows;i++) {
//      row = StringSubstr(mysql_fetch_row(Rez),12,100);
//      Print(row);
//   }         


/*   int num_fields = mysql_num_fields(Rez);   
   string row;
   int i=0;
   row = mysql_fetch_row(Rez);
   while (row)   {
	  int lengths;
	  lengths = mysql_fetch_lengths(Rez);
	  for(i = 0; i < num_fields; i++) {
	  	  Print(lengths,row);
	  }
	  row = mysql_fetch_row(Rez);
   }
*/   
   
   mysql_free_result(Rez);
   return(NumRows);
}
return(0);
}
//+------------------------------------------------------------------+