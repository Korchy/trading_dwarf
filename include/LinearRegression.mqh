//+------------------------------------------------------------------+
//|                                             LinearRegression.mq4 |
//|                                                    Force_Majeure |
//|                                                  force_m@mail.ru |
//+------------------------------------------------------------------+
// LinearRegression - ���������� ������ �������� ��������� �.�. �����
// ������, ������� ������� �� ����� �������, ��� �������� ��������, ��
// ����������� ���������� (������� ������).
// ��. ���������:  BarsCount - �� �������� ��������� ����� �������
//                 ShowLine,LineColor - ���������� ����� � �������� ������, �� ����
// ���. ���������: x1,x2,y1,y2 - ����� �� ������� ����� ��������� ��� ������������ ����� ���������
//+------------------------------------------------------------------+
#property copyright "Force_Majeure"
#property link      "force_m@mail.ru"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
#include <Common.mqh>            // ����� �������
//+------------------------------------------------------------------+
#import "user32.dll"
int GetClientRect(int hWnd,int& lpRect[]); // ������� Win-API ��� ��������� ������� ���� � ��������
#import
//+------------------------------------------------------------------+
//| Functions                                                        |
//+------------------------------------------------------------------+
void LinearRegressionInit() {
   // �����������

return;
}
//+------------------------------------------------------------------+
void LinearRegressionRelease() {
   // ����������

return;
}
//+------------------------------------------------------------------+
double LinearRegression(int BarsCount,string ShowLine,color LineColor,datetime& x1,datetime& x2,double& y1,double& y2) {
   // ������� ���� �������� ��������� � ��������� �� ��������� ��� ���������������� BarsCount �����
double Rez = 0.0;
   // ������� ��������� ������
double A = 0.0;
int B = BarsCount;
double C = 0.0;
double D = 0.0;
double E = 0.0;
for(int i=1;i<=BarsCount;i++) {
   // ������� �� ����� ��������
   A += Close[i];
   C += i;
   D += i*Close[i];
   E += i*i;
}
double a0 = (A*E-D*C)/(B*E-C*C);
double b0 = (D-C*a0)/E;
   // �������� 4 ����� ��� ���������� �������
x1 = Time[1];
y1 = a0+b0*1;
x2 = Time[BarsCount];
y2 = a0+b0*BarsCount;
   // ���� ������� ��� ��� ������������ �������-����� -> ������ ����� ���������
if(ShowLine!="") {
   // ������� �� ���� ��� ��� ���� ���������
   if(ObjectFind(ShowLine)>=0) ObjectDelete(ShowLine);
   // ������� ������ � ������ ����������
   ObjectCreate(ShowLine,OBJ_TREND,0,x1,y1,x2,y2);
   ObjectSet(ShowLine,OBJPROP_RAY,false);
   ObjectSet(ShowLine,OBJPROP_COLOR,LineColor);
   ObjectSet(ShowLine,OBJPROP_WIDTH,2);
}
   // ��������� ���� ������� ������ (�� ���������)
   // �������� HWND �������� ���� �������
int rect[4];
int hwnd = WindowHandle(Symbol(),Period());  // HWND �������� ����
if(hwnd>0) GetClientRect(hwnd,rect);
else return(0.0);
double GPixels = 0.0;   // ���-�� �������� � ���� ������� �� �����������
double VPixels = 0.0;   // ���-�� �������� � ���� ������� �� ���������
   // �������� ������������ ������� �������
GPixels=rect[2]-rect[0]; // ���-�� �������� �� �����������
VPixels=rect[3]-rect[1]; // ���-�� �������� �� ���������
double PriceRange = WindowPriceMax(0)-WindowPriceMin(0);
if(PriceRange==0.0) return(0.0); // �.�. ������� ���� ��������� ������ ����� ������ ��������� ������� (�� 2�� ����)
double VScale = VPixels/PriceRange;
   // �������� �������������� ������� �������
double BarsRange = WindowBarsPerChart();
double GScale = GPixels/BarsRange;
   // �������� ���� �������
double a = (y1-y2)*VScale;  // �������� �� ������� ����� ��������� �������� ����
double b = MathAbs(BarsCount-1)*GScale;
double al = MathArctan(a/b);  // ���� ������� ����� � ����������� � ��������
al = al*180.0/PI; // ��������� � ������� - ������� ���� ������� � ����������� (���� ������ 0 - ������ ����, ������ 0 - �����)
//al = 90.0-al;     // ���� ������� � ��������� � ��������
return(al);
}
//+------------------------------------------------------------------+

