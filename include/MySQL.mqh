//+------------------------------------------------------------------+
//|   MySQL.mqh
//|   Force_Majeure
//|   force_m@mail.ru
//+------------------------------------------------------------------+
// MySQL - ������ � ����� ������ MySQL
//+------------------------------------------------------------------+
#property copyright "Force_Majeure"
#property link      "force_m@mail.ru"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
#import "libmysql.dll"
int mysql_init(int Db);    // ������������� MySQL
void mysql_close(int Db);  // ���������� �� ��
int mysql_errno(int Db);   // ��� ������
int mysql_error(int Db);   // ��������� �������� ������
int mysql_real_connect(int Db, string host, string user, string password,string DB,int port,int socket,int clientflag);   // ������� � ��
int mysql_real_query(int Db, string query, int length);  // ���������� �������
int mysql_store_result(int Db); // ������ � ������������ �������
void mysql_free_result(int Result); // ������ ����������� �������
string mysql_fetch_row(int Result); // �������� ��������� ������ � ���������� �������
int mysql_num_rows(int Result);     // �������� ���-�� ����� � ���������� �������

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
//                            �������
//+------------------------------------------------------------------+
void MySQLInit() {
   // �����������
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
   // ����������
mysql_close(MySQLDatabase);
return;
}
//+------------------------------------------------------------------+
bool MySQLConnect() {
   // ������������� � ���� ������
if(MySQLHost==""||MySQLUser==""||MySQLPassword==""||MySQLDb=="") return(false);
MySQLDatabase = mysql_init(MySQLDatabase);
int Res = mysql_real_connect(MySQLDatabase,MySQLHost,MySQLUser,MySQLPassword,MySQLDb,MySQLPort,MySQLSocket,MySQLClientflag);
int Err = GetLastError();
if(Res!=MySQLDatabase) {
   Print("�� ����������� ���������� c MySQL");
   return(false);
}
return(true);
}
//+------------------------------------------------------------------+
void MySQLUtfToAnsi() {
   // ��������� �������������� ��������� "�� ����" �� UTF8 � ANSI1251
MySQLQuery = "SET CHARACTER SET cp1251_koi8;";
MySQLExec();
return;
}
//+------------------------------------------------------------------+
int MySQLExec() {
   // ���������� �������. ���������� ���-�� ����� � ���������� �������.
if(MySQLQuery=="") return(0);
int Length = StringLen(MySQLQuery);
mysql_real_query(MySQLDatabase,MySQLQuery,Length);
int Err = mysql_errno(MySQLDatabase);
if(Err>0) Print("������ ",Err," ",mysql_error(MySQLDatabase));
   // ����� �� ����� ����������
if(StringSubstr(MySQLQuery,0,6)=="select") {
   int Rez = mysql_store_result(MySQLDatabase);
   int NumRows = mysql_num_rows(Rez);

   // ����� ���������� �������� - �� ����� �������� �.�. mysql_fetch_row ���������� ����������� ��� ������ MYSQL_ROW
   // ������� �� ��������� ������� � /0 � ����� � mysql_num_fields ���������� ��������� �� ������ � � ����������� MQL4
   // �� ��������

// ���� � ������� ���� ��������� ���� - ��� ����� �������� ���:
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