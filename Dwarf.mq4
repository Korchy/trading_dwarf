//+------------------------------------------------------------------+
//|                                                        Dwarf.mq4 |
//|                                                    Force_Majeure |
//|                                                  force_m@mail.ru |
//+------------------------------------------------------------------+
// Dwarf v.1.0
// ��������� �1
// ������ USDEUR
// ������� - ����������� ������� 1:1, ��������� +/- ����� ����� ����� ���������� �������� � 1 �������.
// ������ �� ���� �����. ������� ����� ��������� �.�. �� ������ �� ����������� ����� ��������� (�� ���� �������).
//+------------------------------------------------------------------+
#property copyright "Force_Majeure"
#property link      "force_m@mail.ru"
//+------------------------------------------------------------------+
#define EXPERT_ID 1000  // ID ��������, ��������� � �������, ����� ��������� 3 ����� �� �����������, ��� ����� ��� ������������ MagicId � �������. �.�. ID ������� �������� = 1
//+------------------------------------------------------------------+
#include <Common.mqh>            // ����� �������
#include <Graphic.mqh>           // ����������� ����������
#include <OrderControl.mqh>      // ��� ������ � ��������
#include <LinearRegression.mqh>  // ���������� ����� �������� ���������
//+------------------------------------------------------------------+
extern double WorkingLotVolume = 0.1;  // ����� ����� ������� ����� ���������-���������
extern int ShortTenBarsCount = 5;   // �������� ��������� - ������ ����� �� X ��� �������������� �����
extern int MiddleTenBarsCount = 45; // ������� ��������� - ������ ����� �� X ��� �������������� �����
extern int LongTenBarsCount = 90;   // ������� ��������� - ������ ����� �� X ��� �������������� �����
extern int MRealChangedBarsCount = 40;  // ���� ���� ���� ��������� ��������� � � ������� ����� ���-�� ����� �� ������������ ������� - ������� ��� �� ��� ����� ��������� � �� �������� (��� �� ������)
extern int LCloseAngle = 20;  // ���� ������� ��������� ��� ������� ���� ��� �������������� ������ ������� ��� ����� ����� �������
extern int MovingSAngle = 0;   // ���� �������� ��������� ����������� �� ����������� ������ ��� �� ���� ���� - ������� ��� ���� ���� ��� ����, ���� ������ ����� ���� - �������� ������
extern int MovingMAngle = 0;   // ���� ������� ��������� ����������� �� ����������� ������ ��� �� ���� ���� - ������� ��� ���� ���� ��� ����, ���� ������ ����� ���� - �������� ������
extern int MovingLAngle = 20;   // ���� ������� ��������� ����������� �� ����������� ������ ��� �� ���� ���� - ������� ��� ���� ���� ��� ����, ���� ������ ����� ���� - �������� ������
extern int SlAddValue = 40;   // �� ������ ���-�� ������� ��������� �������� ������������ ����-����
extern int OrderLife=0;   // ����� ����� ������ � ����� (�� ��������� �������� ����� �����������). 0 - ����������
extern int OrderAfterLife=0;   // ����� ����� �������� ������, ������� ������ ��������� ����� ������. 0 - �� �����������, 1 - ����� ��������� �����
//+------------------------------------------------------------------+
static datetime LastBarTime;  // ����������� ���������� ��� ����������� ��������� ������ ���� (������ ����� ��������� ���������� ����)
static int LotMagic; // ����������� ���������� ��� �������� MagicID �������� ��������� ������
static int OrderTime;   // ����������� ���������� ��� �������� ����������� ������� ����� OrderLife �������� ��������� ������
static int OrderAfterTime;   // ����������� ���������� ��� �������� ����������� ������� OrderAfterLife
//+------------------------------------------------------------------+
int MovingS[2][4]; // ������, ����������� ����������� �������� ���������
   // [1-������,2-������,3-����][������������=���-�� �����][��������=�����(����)][id] - ������� ��������
   // [1-������,2-������,3-����][������������=���-�� �����][��������=�����(����)][id] - ����������� ��-�, ������� ���� �� ��������
int MovingM[2][4]; // ������, ����������� ����������� ������� ���������
   // [1-������,2-������,3-����][������������=���-�� �����][��������=�����(����)][id] - ��������� (�����) ����������� ��������
   // [1-������,2-������,3-����][������������=���-�� �����][��������=�����(����)][id] - ��������� (�����) ����������� ��������, ������� ���� �� ��������
int MovingL[2][4]; // ������, ����������� ����������� ������� ���������
   // [1-������,2-������,3-����][������������=���-�� �����][��������=�����(����)][id] - ��������� (�����) ����������� ��������
   // [1-������,2-������,3-����][������������=���-�� �����][��������=�����(����)][id] - ��������� (�����) ����������� ��������, ������� ���� �� ��������
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init() {
   // ��� ������� ��������
LotMagic = EXPERT_ID+1;
   // ��� ����������� ������� ������������ ������ ����
LastBarTime = 0;
   // ��� �������� �� �������� ����� � ���������� �������
OrderTime=0;
OrderAfterTime=0;
   // ������������� OrderControl
OrderControlInit();
   // ������������� LinearRegression
LinearRegressionInit();
   // �������� ������� ��� �������� ���������� � ��������� ���������
ArrayInitialize(MovingS,0);
ArrayInitialize(MovingM,0);
ArrayInitialize(MovingL,0);
   // ������ ��� ������ ���������� � ���� �������� ���������
//ObjectCreate("ShortTenLable",OBJ_LABEL,0,0,0,0,0);
//ObjectSet("ShortTenLable",OBJPROP_XDISTANCE,10);
//ObjectSet("ShortTenLable",OBJPROP_YDISTANCE,20);
//ObjectSetText("ShortTenLable","",8,"Courier",Gold);
   // ������ ��� ������ ���������� � ���� ������� ���������
ObjectCreate("MiddleTenLable",OBJ_LABEL,0,0,0,0,0);
ObjectSet("MiddleTenLable",OBJPROP_XDISTANCE,10);
ObjectSet("MiddleTenLable",OBJPROP_YDISTANCE,35);
ObjectSetText("MiddleTenLable","",8,"Courier",Gold);
   // ������ ��� ������ ���������� � ���� ������� ���������
ObjectCreate("LongTenLable",OBJ_LABEL,0,0,0,0,0);
ObjectSet("LongTenLable",OBJPROP_XDISTANCE,10);
ObjectSet("LongTenLable",OBJPROP_YDISTANCE,50);
ObjectSetText("LongTenLable","",8,"Courier",Gold);
   // ������ ��� ������ ���������� � �������� ��������
//ObjectCreate("MoovingSLable0",OBJ_LABEL,0,0,0,0,0);
//ObjectSet("MoovingSLable0",OBJPROP_XDISTANCE,10);
//ObjectSet("MoovingSLable0",OBJPROP_YDISTANCE,65);
//ObjectSetText("MoovingSLable0","",8,"Courier",Gold);
//ObjectCreate("MoovingSLable1",OBJ_LABEL,0,0,0,0,0);
//ObjectSet("MoovingSLable1",OBJPROP_XDISTANCE,10);
//ObjectSet("MoovingSLable1",OBJPROP_YDISTANCE,80);
//ObjectSetText("MoovingSLable1","",8,"Courier",Gold);
   // ������ ��� ������ ���������� � ������� ��������
ObjectCreate("MoovingMLable0",OBJ_LABEL,0,0,0,0,0);
ObjectSet("MoovingMLable0",OBJPROP_XDISTANCE,10);
ObjectSet("MoovingMLable0",OBJPROP_YDISTANCE,95);
ObjectSetText("MoovingMLable0","",8,"Courier",Gold);
ObjectCreate("MoovingMLable1",OBJ_LABEL,0,0,0,0,0);
ObjectSet("MoovingMLable1",OBJPROP_XDISTANCE,10);
ObjectSet("MoovingMLable1",OBJPROP_YDISTANCE,110);
ObjectSetText("MoovingMLable1","",8,"Courier",Gold);
   // ������ ��� ������ ���������� � ������� ��������
ObjectCreate("MoovingLLable0",OBJ_LABEL,0,0,0,0,0);
ObjectSet("MoovingLLable0",OBJPROP_XDISTANCE,10);
ObjectSet("MoovingLLable0",OBJPROP_YDISTANCE,125);
ObjectSetText("MoovingLLable0","",8,"Courier",Gold);
ObjectCreate("MoovingLLable1",OBJ_LABEL,0,0,0,0,0);
ObjectSet("MoovingLLable1",OBJPROP_XDISTANCE,10);
ObjectSet("MoovingLLable1",OBJPROP_YDISTANCE,140);
ObjectSetText("MoovingLLable1","",8,"Courier",Gold);
   // ���������� ������ - ������ ������ ���������
CreateStartLine("Dwarf");
return(0);
}
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit() {
   // ��� ������ �� ��������
   // ��������������� OrderControl
OrderControlRelease();
   // ������������� LinearRegression
LinearRegressionRelease();
   // ����� ������ ������
DeleteStartLine("Dwarf");
   // ���� �������� ���������
//ObjectDelete("ShortTenLable");
ObjectDelete("MiddleTenLable");
ObjectDelete("LongTenLable");
   // ���� ��������
//ObjectDelete("MoovingSLable0");
//ObjectDelete("MoovingSLable1");
ObjectDelete("MoovingMLable0");
ObjectDelete("MoovingMLable1");
ObjectDelete("MoovingLLable0");
ObjectDelete("MoovingLLable1");
return(0);
}
//+------------------------------------------------------------------+
//| expert start function                                            |
//+------------------------------------------------------------------+
int start() {
   // ������ ���
   // ���������� ������, ���� ���� ������� �� �� ���������
OrderControl();
   // ��������, �������������-�� ��������� ���
if(LastBarTime==Time[0]) return(0); // ����� ��� ��� �� �����������
LastBarTime = Time[0];  // �������� ����� ���
   // �������� ���� �������� ��������� ��� �������� ���������
datetime Sx1 = 0;
datetime Sx2 = 0;
double Sy1 = 0.0;
double Sy2 = 0.0;
//double Sal = LinearRegression(ShortTenBarsCount,"ShortLinearRegressionLine",Blue,Sx1,Sx2,Sy1,Sy2);
double Sal = LinearRegression(ShortTenBarsCount,"",Blue,Sx1,Sx2,Sy1,Sy2);
   // ���� ������� �������� ��������� ������� �� �����
//ObjectSetText("ShortTenLable","���� �������� ��������� ("+ShortTenBarsCount+"-Bars): "+DoubleToStr(Sal,4),8,"Courier",Gold);
   // �������� ���� �������� ��������� ��� ������� ���������
datetime Mx1 = 0;
datetime Mx2 = 0;
double My1 = 0.0;
double My2 = 0.0;
double Mal = LinearRegression(MiddleTenBarsCount,"MiddleLinearRegressionLine",Orange,Mx1,Mx2,My1,My2);
   // ���� ������� ������� ��������� ������� �� �����
ObjectSetText("MiddleTenLable","���� ������� ��������� ("+MiddleTenBarsCount+"-Bars): "+DoubleToStr(Mal,4),8,"Courier",Gold);
   // �������� ���� �������� ��������� ��� ������� ���������
datetime Lx1 = 0;
datetime Lx2 = 0;
double Ly1 = 0.0;
double Ly2 = 0.0;
double Lal = LinearRegression(LongTenBarsCount,"LongLinearRegressionLine",LawnGreen,Lx1,Lx2,Ly1,Ly2);
   // ���� ������� ������� ��������� ������� �� �����
ObjectSetText("LongTenLable","���� ������� ��������� ("+LongTenBarsCount+"-Bars): "+DoubleToStr(Lal,4),8,"Courier",Gold);
   // ��������� ��������� ��������
int MovingSChanged = MOVING_NOT_CHANGED;
int MovingMChanged = MOVING_NOT_CHANGED;
int MovingLChanged = MOVING_NOT_CHANGED;
   // ������� ������ � ������ �������� Moving
   // �������� ���������
if(Sal>MovingSAngle) {
   // �������� - ������
   if(MovingS[0][0]!=MOVING_UP) {   // ��������� �������� - ������� ������
      MovingSChanged = MOVING_CHANGED_TO_UP;
      // ��������� ������ �������� �� ������ ������ �������
      MovingS[1][0]=MovingS[0][0];
      MovingS[1][1]=MovingS[0][1];
      MovingS[1][2]=MovingS[0][2];
      MovingS[1][3]=MovingS[0][3];
      // ������� � 1 ������ ������� ����� ��������
      MovingS[0][0]=MOVING_UP;
      MovingS[0][1]=1;
      MovingS[0][2]=Sal;
      MovingS[0][3]++;
   }
   else {   // �������� ������������
      MovingS[0][1]++;
      MovingS[0][2]+=Sal;
   }
}
else if(Sal<-MovingSAngle) {
   // �������� - ����
   if(MovingS[0][0]!=MOVING_DOWN) {   // ��������� �������� - ������� ����
      MovingSChanged = MOVING_CHANGED_TO_DOWN;
      // ��������� ������ �������� �� ������ ������ �������
      MovingS[1][0]=MovingS[0][0];
      MovingS[1][1]=MovingS[0][1];
      MovingS[1][2]=MovingS[0][2];
      MovingS[1][3]=MovingS[0][3];
      // ������� � 1 ������ ������� ����� ��������
      MovingS[0][0]=MOVING_DOWN;
      MovingS[0][1]=1;
      MovingS[0][2]=Sal;
      MovingS[0][3]++;
   }
   else {   // �������� ������������
      MovingS[0][1]++;
      MovingS[0][2]+=Sal;
   }
}
   // ������� ���������
if(Mal>MovingMAngle) {
   // �������� - ������
   if(MovingM[0][0]!=MOVING_UP) {   // ��������� �������� - ������� ������
      MovingMChanged = MOVING_CHANGED_TO_UP;
      // ��������� ������ �������� �� ������ ������ �������
      MovingM[1][0]=MovingM[0][0];
      MovingM[1][1]=MovingM[0][1];
      MovingM[1][2]=MovingM[0][2];
      MovingM[1][3]=MovingM[0][3];
      // ������� � 1 ������ ������� ����� ��������
      MovingM[0][0]=MOVING_UP;
      MovingM[0][1]=1;
      MovingM[0][2]=Mal;
      MovingM[0][3]++;
   }
   else {   // �������� ������������
      MovingM[0][1]++;
      MovingM[0][2]+=Mal;
   }
}
else if(Mal<-MovingMAngle) {
   // �������� - ����
   if(MovingM[0][0]!=MOVING_DOWN) {   // ��������� �������� - ������� ����
      MovingMChanged = MOVING_CHANGED_TO_DOWN;
      // ��������� ������ �������� �� ������ ������ �������
      MovingM[1][0]=MovingM[0][0];
      MovingM[1][1]=MovingM[0][1];
      MovingM[1][2]=MovingM[0][2];
      MovingM[1][3]=MovingM[0][3];
      // ������� � 1 ������ ������� ����� ��������
      MovingM[0][0]=MOVING_DOWN;
      MovingM[0][1]=1;
      MovingM[0][2]=Mal;
      MovingM[0][3]++;
   }
   else {   // �������� ������������
      MovingM[0][1]++;
      MovingM[0][2]+=Mal;
   }
}
   // ������� ���������
if(Lal>MovingLAngle) {
   // �������� - ������
   if(MovingL[0][0]!=MOVING_UP) {   // ��������� �������� - ������� ������
      MovingLChanged = MOVING_CHANGED_TO_UP;
      // ��������� ������ �������� �� ������ ������ �������
      MovingL[1][0]=MovingL[0][0];
      MovingL[1][1]=MovingL[0][1];
      MovingL[1][2]=MovingL[0][2];
      MovingL[1][3]=MovingL[0][3];
      // ������� � 1 ������ ������� ����� ��������
      MovingL[0][0]=MOVING_UP;
      MovingL[0][1]=1;
      MovingL[0][2]=Lal;
      MovingL[0][3]++;
   }
   else {   // �������� ������������
      MovingL[0][1]++;
      MovingL[0][2]+=Lal;
   }
}
else if(Lal<-MovingLAngle) {
   // �������� - ����
   if(MovingL[0][0]!=MOVING_DOWN) {   // ��������� �������� - ������� ����
      MovingLChanged = MOVING_CHANGED_TO_DOWN;
      // ��������� ������ �������� �� ������ ������ �������
      MovingL[1][0]=MovingL[0][0];
      MovingL[1][1]=MovingL[0][1];
      MovingL[1][2]=MovingL[0][2];
      MovingL[1][3]=MovingL[0][3];
      // ������� � 1 ������ ������� ����� ��������
      MovingL[0][0]=MOVING_DOWN;
      MovingL[0][1]=1;
      MovingL[0][2]=Lal;
      MovingL[0][3]++;
   }
   else {   // �������� ������������
      MovingL[0][1]++;
      MovingL[0][2]+=Lal;
   }
}
   // ���������� � �������� - �� �����
string MovingTxt[4] = {"???   ","������","������","����  "};
//ObjectSetText("MoovingSLable0","�������� �������� ���������       : "+MovingTxt[MovingS[0][0]]+" "+MovingS[0][1]+" "+MovingS[0][2]+" "+MovingS[0][3],8,"Courier",Gold);
//ObjectSetText("MoovingSLable1","���������� ��-� �������� ���������: "+MovingTxt[MovingS[1][0]]+" "+MovingS[1][1]+" "+MovingS[1][2]+" "+MovingS[1][3],8,"Courier",Gold);
ObjectSetText("MoovingMLable0","�������� ������� ���������        : "+MovingTxt[MovingM[0][0]]+" "+MovingM[0][1]+" "+MovingM[0][2]+" "+MovingM[0][3],8,"Courier",Gold);
ObjectSetText("MoovingMLable1","���������� ��-� ������� ��������� : "+MovingTxt[MovingM[1][0]]+" "+MovingM[1][1]+" "+MovingM[1][2]+" "+MovingM[1][3],8,"Courier",Gold);
ObjectSetText("MoovingLLable0","�������� ������� ���������        : "+MovingTxt[MovingL[0][0]]+" "+MovingL[0][1]+" "+MovingL[0][2]+" "+MovingL[0][3],8,"Courier",Gold);
ObjectSetText("MoovingLLable1","���������� ��-� ������� ��������� : "+MovingTxt[MovingL[1][0]]+" "+MovingL[1][1]+" "+MovingL[1][2]+" "+MovingL[1][3],8,"Courier",Gold);
/*
ObjectCreate(LastBarTime+"BarText",OBJ_TEXT,0,Time[1],Close[1]+Close[1]*0.15/100,0,0);
ObjectSetText(LastBarTime+"BarText",MovingTxt[MovingS[0][0]]+" "+MovingS[0][1]+" "+MovingS[0][2]+" "+MovingS[0][3],7,"Arial",Gold);
ObjectSet(LastBarTime+"BarText",OBJPROP_ANGLE,-90);
*/
   // ������ � ��������
double STVariation = MarketInfo(Symbol(),MODE_STOPLEVEL)*Point+Point;  // ����������� ���������� ���� ��� ��������� StopLoss � TakeProfit (����� �� 1 ����� ������ ������������ �.�. �������� ���� ����� ������)
double BuySl = Bid-(STVariation+Point*SlAddValue);  // ����-���� ��� Buy-������
double SellSl = Ask+(STVariation+Point*SlAddValue);  // ����-���� ��� Sell-������
   // ��������� - ����-�� �������� ������
bool OrderCreated = false;
int CurrentOrder = 0;
int CurrentOrderType = OP_BUY;
bool Rez = false;
for(int i=0;i<OrdersTotal();i++) {// �� ���� �������� ������� ���������
   // ���� ���� �������� ����� �� ������ ������� � MagicId ������� ��������
   if((OrderSelect(i,SELECT_BY_POS)==true)&&(OrderSymbol()==Symbol())&&(OrderMagicNumber()==LotMagic)) {
      OrderCreated = true;
      CurrentOrder = OrderTicket();
      CurrentOrderType = OrderType();
      break;
   }
}
if(OrderCreated==false) {
   // �������� ������� ���
   // ��������� �� ����������� �������� ������ �� �������� OrderAfterLife
   if(OrderAfterTime>0) OrderAfterTime--;
   if(OrderAfterTime<=0) {
      // ��������� �� ������������� �������� ������
      // (������� ��������� ���� �����) � (���� ������ MovingLAngle) � (������ ����� ������� ��������� ���� �������� Ask �� ������ ��� �� STVariation - ����� ��������������� ������ ������) � (������� ���� �����)-> ������� Buy-�����
      if(MovingL[0][0]==MOVING_UP&&Lal>=MovingLAngle&&(Ly1-Ask<STVariation)&&MovingM[0][0]==MOVING_UP) {
         LotMagic++;
         OrderTime=OrderLife; // ������ �������� ���� OrderLife �����
         Rez = AddOrderToControl(OPEN_ORDER,0,OP_BUY,WorkingLotVolume,false,BuySl,false,0.0,LotMagic);
         if(Rez!=false) {
         // ������� ������ ��������� ��� ����������
         ObjectCreate("BuyL-"+LotMagic,OBJ_TREND,0,Lx1,Ly1,Lx2,Ly2);
         ObjectSet("BuyL-"+LotMagic,OBJPROP_RAY,false);
         ObjectSet("BuyL-"+LotMagic,OBJPROP_COLOR,Aqua);
         ObjectSet("BuyL-"+LotMagic,OBJPROP_WIDTH,2);
         }
      }
      // (������� ��������� ���� ����) � (���� ������ MovingLAngle) � (������ ����� ������� ��������� ���� �������� Bid �� ������ ��� �� STVariation - ����� ��������������� ������ ������) � (������� ���� ����) -> ������� Sell-�����
      if(MovingL[0][0]==MOVING_DOWN&&Lal<=-MovingLAngle&&(Bid-Ly1<STVariation)&&MovingM[0][0]==MOVING_DOWN) {
         LotMagic++;
         OrderTime=OrderLife; // ������ �������� ���� OrderLife �����
         Rez = AddOrderToControl(OPEN_ORDER,0,OP_SELL,WorkingLotVolume,false,SellSl,false,0.0,LotMagic);
         if(Rez!=false) {
         // ������� ������ ��������� ��� ����������
         ObjectCreate("SellL-"+LotMagic,OBJ_TREND,0,Lx1,Ly1,Lx2,Ly2);
         ObjectSet("SellL-"+LotMagic,OBJPROP_RAY,false);
         ObjectSet("SellL-"+LotMagic,OBJPROP_COLOR,Aqua);
         ObjectSet("SellL-"+LotMagic,OBJPROP_WIDTH,2);
         }
      }
   }
}
else {
   // ���� �������� ����� -> ������ � �������� �������
   OrderTime--;   // ����� ����� ������ ��������� �� 1
   // ��������� �� ������������� ������������� ������
   bool SlMoving = true;
   if(CurrentOrderType==OP_BUY&&OrderStopLoss()>=BuySl) SlMoving = false;
   if(CurrentOrderType==OP_SELL&&OrderStopLoss()<=SellSl) SlMoving = false;
   // (���� ���-�� ����� ��� ������� ��������� >1 ��������� �� ��������) � (����-���� ���������� �� ������ ��������) -> ������������� ������
   if(CurrentOrderType==OP_BUY) {
      if(MovingL[0][1]>1&&SlMoving==true) {
         Rez = AddOrderToControl(CORRECT_ORDER,CurrentOrder,CurrentOrderType,WorkingLotVolume,false,BuySl,false,0.0,LotMagic);
      }
   }
   else {
      if(MovingL[0][1]>1&&SlMoving==true) {
         Rez = AddOrderToControl(CORRECT_ORDER,CurrentOrder,CurrentOrderType,WorkingLotVolume,false,SellSl,false,0.0,LotMagic);
      }
   }
   // ��������� �� ������������� �������� ������
   // ����� ����� ������ == 1
   if((OrderTime==1)) {
      Rez = AddOrderToControl(CLOSE_ORDER,CurrentOrder,CurrentOrderType,WorkingLotVolume,true,0.0,false,0.0,LotMagic);
      OrderAfterTime = OrderAfterLife;
      ObjectCreate(LastBarTime+"BarText",OBJ_TEXT,0,Time[1],Close[1]+Close[1]*0.5/100,0,0);
      ObjectSetText(LastBarTime+"BarText","����� ����� ("+OrderLife+") �������",7,"Arial",Gold);
      ObjectSet(LastBarTime+"BarText",OBJPROP_ANGLE,-90);
   }
   // ������� ��������� �������������� ������ � �� ���� >= LCloseAngle
   if((Lal<=-LCloseAngle&&CurrentOrderType==OP_BUY)||(Lal>=LCloseAngle&&CurrentOrderType==OP_SELL)) {
      Rez = AddOrderToControl(CLOSE_ORDER,CurrentOrder,CurrentOrderType,WorkingLotVolume,true,0.0,false,0.0,LotMagic);
      OrderAfterTime = OrderAfterLife;
      ObjectCreate(LastBarTime+"BarText",OBJ_TEXT,0,Time[1],Close[1]+Close[1]*0.5/100,0,0);
      ObjectSetText(LastBarTime+"BarText","��. ��������� �������������� ������ � �� ���� >= LCloseAngle",7,"Arial",Gold);
      ObjectSet(LastBarTime+"BarText",OBJPROP_ANGLE,-90);
   }
   // ������� ��������� �������������� �� ����� ������ � ������������ ������ MRealChangedBarsCount �����
   if(((Mal<0&&CurrentOrderType==OP_BUY)||(Mal>0&&CurrentOrderType==OP_SELL))&&MovingM[0][1]>=MRealChangedBarsCount) {
      Rez = AddOrderToControl(CLOSE_ORDER,CurrentOrder,CurrentOrderType,WorkingLotVolume,true,0.0,false,0.0,LotMagic);
      OrderAfterTime = OrderAfterLife;
      ObjectCreate(LastBarTime+"BarText",OBJ_TEXT,0,Time[1],Close[1]+Close[1]*0.5/100,0,0);
      ObjectSetText(LastBarTime+"BarText","��. ��������� �������������� ������ � ������������ "+MRealChangedBarsCount+" �����",7,"Arial",Gold);
      ObjectSet(LastBarTime+"BarText",OBJPROP_ANGLE,-90);
   }
}
return(0);
}
//+------------------------------------------------------------------+

