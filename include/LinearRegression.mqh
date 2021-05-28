//+------------------------------------------------------------------+
//|                                             LinearRegression.mq4 |
//|                                                    Force_Majeure |
//|                                                  force_m@mail.ru |
//+------------------------------------------------------------------+
// LinearRegression - Построение прямой линейной регрессии т.е. такой
// прямой, которая отстоит от точек графика, для которого строится, на
// минимальное расстояние (средняя прямая).
// Вх. параметры:  BarsCount - по скольким последним барам считать
//                 ShowLine,LineColor - показывать линию с заданным именем, ее цвет
// Вых. параметры: x1,x2,y1,y2 - точки по которым можно построить уже подсчитанную линию регрессии
//+------------------------------------------------------------------+
#property copyright "Force_Majeure"
#property link      "force_m@mail.ru"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
#include <Common.mqh>            // Общие функции
//+------------------------------------------------------------------+
#import "user32.dll"
int GetClientRect(int hWnd,int& lpRect[]); // Функция Win-API для получения размера окна в пикселах
#import
//+------------------------------------------------------------------+
//| Functions                                                        |
//+------------------------------------------------------------------+
void LinearRegressionInit() {
   // Конструктор

return;
}
//+------------------------------------------------------------------+
void LinearRegressionRelease() {
   // Деструктор

return;
}
//+------------------------------------------------------------------+
double LinearRegression(int BarsCount,string ShowLine,color LineColor,datetime& x1,datetime& x2,double& y1,double& y2) {
   // Считаем угол линейной регрессии к вертикали по последним уже сформировавшимся BarsCount барам
double Rez = 0.0;
   // Считаем уравнения прямой
double A = 0.0;
int B = BarsCount;
double C = 0.0;
double D = 0.0;
double E = 0.0;
for(int i=1;i<=BarsCount;i++) {
   // Считаем по ценам закрытия
   A += Close[i];
   C += i;
   D += i*Close[i];
   E += i*i;
}
double a0 = (A*E-D*C)/(B*E-C*C);
double b0 = (D-C*a0)/E;
   // Получаем 4 точки для построения отрезка
x1 = Time[1];
y1 = a0+b0*1;
x2 = Time[BarsCount];
y2 = a0+b0*BarsCount;
   // Если указано имя для визуализации объекта-линии -> строим линию регрессии
if(ShowLine!="") {
   // Удалить ее если она уже была построена
   if(ObjectFind(ShowLine)>=0) ObjectDelete(ShowLine);
   // Создать заново с новыми значениями
   ObjectCreate(ShowLine,OBJ_TREND,0,x1,y1,x2,y2);
   ObjectSet(ShowLine,OBJPROP_RAY,false);
   ObjectSet(ShowLine,OBJPROP_COLOR,LineColor);
   ObjectSet(ShowLine,OBJPROP_WIDTH,2);
}
   // Расчитать угол наклона прямой (От вертикали)
   // Получить HWND текущего окна графика
int rect[4];
int hwnd = WindowHandle(Symbol(),Period());  // HWND текущего окна
if(hwnd>0) GetClientRect(hwnd,rect);
else return(0.0);
double GPixels = 0.0;   // Кол-во пикселей в окне графика по горизонтали
double VPixels = 0.0;   // Кол-во пикселей в окне графика по вертикали
   // Получить вертикальный масштаб графика
GPixels=rect[2]-rect[0]; // Кол-во пикселов по горизонтали
VPixels=rect[3]-rect[1]; // Кол-во пикселов по вертикали
double PriceRange = WindowPriceMax(0)-WindowPriceMin(0);
if(PriceRange==0.0) return(0.0); // т.к. размеры окна считаются только после первой отрисовки графика (со 2го тика)
double VScale = VPixels/PriceRange;
   // Получить горизонтальный масштаб графика
double BarsRange = WindowBarsPerChart();
double GScale = GPixels/BarsRange;
   // Получить угол наклона
double a = (y1-y2)*VScale;  // Умножать на масштаб чтобы правильно считался угол
double b = MathAbs(BarsCount-1)*GScale;
double al = MathArctan(a/b);  // Угол наклона линии к горизонтали в радианах
al = al*180.0/PI; // Переведем в градусы - получим угол наклона к горизонтали (угол меньше 0 - наклон вниз, больше 0 - вверх)
//al = 90.0-al;     // Угол наклона к вертикали в градусах
return(al);
}
//+------------------------------------------------------------------+

