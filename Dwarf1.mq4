//+------------------------------------------------------------------+
//|                                                       Dwarf1.mq4 |
//|                                                    Force_Majeure |
//|                                                  force_m@mail.ru |
//+------------------------------------------------------------------+
// Dwarf v.2.0
//+------------------------------------------------------------------+
#property copyright "Force_Majeure"
#property link      "force_m@mail.ru"
//+------------------------------------------------------------------+
#define EXPERT_ID 2000  // ID ��������, ��������� � �������, ����� ��������� 3 ����� �� �����������, ��� ����� ��� ������������ MagicId � �������. �.�. ID ������� �������� = 1
//+------------------------------------------------------------------+
#include <Common.mqh>            // ����� �������
#include <MySQL.mqh>             // ��� ������ � ����� ������ MySQL
//+------------------------------------------------------------------+
static datetime LastBarTime;  // ����������� ���������� ��� ����������� ��������� ������ ���� (������ ����� ��������� ���������� ����)
static int UpdateBarNo;       // ����������� ���������� � ������� �������� � ���� ������� ����� ��������� �� �������/����������
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init() {
   // ��� ������� ��������
   // ��� ����������� ������� ������������ ������ ����
LastBarTime = 0;
   // ������� � ���� ������
MySQLInit();
MySQLHost = "localhost";
MySQLUser = "root";
MySQLPassword = "fm191919";
MySQLDb = "forexdb";
MySQLConnect();
MySQLUtfToAnsi();
   // �������� ����� �������� � 1-�� (�.�. ������� ��� �� ������������� �� �����)
UpdateBarNo = 1;  
return(0);
}
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit() {
   // ��� ������ �� ��������
   // ���������� �� ��
MySQLRelease();
return(0);
}
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start() {
   // ������ ���
   // ��������� ������ ���� �� ����������
if(UpdateBarNo<=1051200) { // ��������� �� 2 ���� �����
   MySQLQuery = "select * from `eurusdm1` where time=\'"+TimeToStr(Time[UpdateBarNo],TIME_DATE|TIME_SECONDS)+"\';";
   int Rez = MySQLExec();
   if(Rez>1) MessageBox("������������ ����� � ��","!!!");
   if(Rez==0) MySQLQuery = "insert into eurusdm1 (time,open,close,high,low,volume) values(\'"+TimeToStr(Time[UpdateBarNo],TIME_DATE|TIME_SECONDS)+"\',"+Open[UpdateBarNo]+","+Close[UpdateBarNo]+","+High[UpdateBarNo]+","+Low[UpdateBarNo]+","+Volume[UpdateBarNo]+");";
   if(Rez==1) MySQLQuery = "update eurusdm1 set open="+Open[UpdateBarNo]+",close="+Close[UpdateBarNo]+",high="+High[UpdateBarNo]+",low="+Low[UpdateBarNo]+",volume="+Volume[UpdateBarNo]+"where time=\'"+TimeToStr(Time[UpdateBarNo],TIME_DATE|TIME_SECONDS)+"\';";
//   Print(MySQLQuery);
   Rez = MySQLExec();
   UpdateBarNo++;
}
   // ��� ������������ ������ ����
   // ��������, �������������-�� ��������� ���
if(LastBarTime==Time[0]) return(0); // ����� ��� ��� �� �����������
LastBarTime = Time[0];  // �������� ����� ���
   // �������� ���������� � ���� ������
MySQLQuery = "select * from `eurusdm1` where time=\'"+TimeToStr(Time[1],TIME_DATE|TIME_SECONDS)+"\';";
Rez = MySQLExec();
if(Rez>1) MessageBox("������������ ����� � ��","!!!");
if(Rez==0) MySQLQuery = "insert into eurusdm1 (time,open,close,high,low,volume) values(\'"+TimeToStr(Time[1],TIME_DATE|TIME_SECONDS)+"\',"+Open[1]+","+Close[1]+","+High[1]+","+Low[1]+","+Volume[1]+");";
if(Rez==1) MySQLQuery = "update eurusdm1 set open="+Open[1]+",close="+Close[1]+",high="+High[1]+",low="+Low[1]+",volume="+Volume[1]+"where time=\'"+TimeToStr(Time[1],TIME_DATE|TIME_SECONDS)+"\';";
//Print(MySQLQuery);
Rez = MySQLExec();
return(0);
}
//+------------------------------------------------------------------+

