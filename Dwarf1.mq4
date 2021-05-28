//+------------------------------------------------------------------+
//|                                                       Dwarf1.mq4 |
//|                                                           Nikita |
//|                                                  force_m@mail.ru |
//+------------------------------------------------------------------+
// Dwarf v.2.0
//+------------------------------------------------------------------+
#property copyright "Nikita"
#property link      "force_m@mail.ru"
//+------------------------------------------------------------------+
#define EXPERT_ID 2000  // ID эксперта, считается в тысячах, чтобы последние 3 цифры не учитывались, они нужны для формирования MagicId в ордерах. Т.е. ID данного эксперта = 1
//+------------------------------------------------------------------+
#include <Common.mqh>            // Общие функции
#include <MySQL.mqh>             // Для работы с базой данных MySQL
//+------------------------------------------------------------------+
static datetime LastBarTime;  // Статическая переменная для определения появления нового бара (хранит время появления последнего бара)
static int UpdateBarNo;       // Статическая переменная в которой хранится № бара который нужно проверить на вставку/обновление
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init() {
   // При запуске эксперта
   // Для определения момента формирования нового бара
LastBarTime = 0;
   // Коннект к базе данных
MySQLInit();
MySQLHost = "localhost";
MySQLUser = "";
MySQLPassword = "";
MySQLDb = "forexdb";
MySQLConnect();
MySQLUtfToAnsi();
   // Проверку баров начинаем с 1-го (т.к. нулевой еще не сформировался до концп)
UpdateBarNo = 1;  
return(0);
}
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit() {
   // При выходе из эксперта
   // Отключение от БД
MySQLRelease();
return(0);
}
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start() {
   // Каждый тик
   // Проверяем старые бары на обновление
if(UpdateBarNo<=1051200) { // Проверяем за 2 года назад
   MySQLQuery = "select * from `eurusdm1` where time=\'"+TimeToStr(Time[UpdateBarNo],TIME_DATE|TIME_SECONDS)+"\';";
   int Rez = MySQLExec();
   if(Rez>1) MessageBox("Задвоенность баров в БД","!!!");
   if(Rez==0) MySQLQuery = "insert into eurusdm1 (time,open,close,high,low,volume) values(\'"+TimeToStr(Time[UpdateBarNo],TIME_DATE|TIME_SECONDS)+"\',"+Open[UpdateBarNo]+","+Close[UpdateBarNo]+","+High[UpdateBarNo]+","+Low[UpdateBarNo]+","+Volume[UpdateBarNo]+");";
   if(Rez==1) MySQLQuery = "update eurusdm1 set open="+Open[UpdateBarNo]+",close="+Close[UpdateBarNo]+",high="+High[UpdateBarNo]+",low="+Low[UpdateBarNo]+",volume="+Volume[UpdateBarNo]+"where time=\'"+TimeToStr(Time[UpdateBarNo],TIME_DATE|TIME_SECONDS)+"\';";
//   Print(MySQLQuery);
   Rez = MySQLExec();
   UpdateBarNo++;
}
   // При формировании нового бара
   // Проверим, сформировался-ли очередной бар
if(LastBarTime==Time[0]) return(0); // Новый бар еще не сформирован
LastBarTime = Time[0];  // Появился новый бар
   // Обновить информацию в базе данных
MySQLQuery = "select * from `eurusdm1` where time=\'"+TimeToStr(Time[1],TIME_DATE|TIME_SECONDS)+"\';";
Rez = MySQLExec();
if(Rez>1) MessageBox("Задвоенность баров в БД","!!!");
if(Rez==0) MySQLQuery = "insert into eurusdm1 (time,open,close,high,low,volume) values(\'"+TimeToStr(Time[1],TIME_DATE|TIME_SECONDS)+"\',"+Open[1]+","+Close[1]+","+High[1]+","+Low[1]+","+Volume[1]+");";
if(Rez==1) MySQLQuery = "update eurusdm1 set open="+Open[1]+",close="+Close[1]+",high="+High[1]+",low="+Low[1]+",volume="+Volume[1]+"where time=\'"+TimeToStr(Time[1],TIME_DATE|TIME_SECONDS)+"\';";
//Print(MySQLQuery);
Rez = MySQLExec();
return(0);
}
//+------------------------------------------------------------------+

