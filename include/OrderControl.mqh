//+------------------------------------------------------------------+
//|                                                 OrderControl.mq4 |
//|                                                    Force_Majeure |
//|                                                  force_m@mail.ru |
//+------------------------------------------------------------------+
// OrderControl - ���������� ������ ��� � ������������ ������� �� ������ � ��������
// ���������� � ������ OrdersToControl. ����� ��������� ������� �� ������� ���������.
// ��������� ������� � ������ ������� ������� AddOrderToControl.
//+------------------------------------------------------------------+
#property copyright "Force_Majeure"
#property link      "force_m@mail.ru"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
#define OPEN_ORDER      1  // ������� �����
#define CLOSE_ORDER     2  // ������� �����
#define CORRECT_ORDER   3  // �������� �����

#define ORDERS_TO_CONTROL  10 // ���-�� �������, ������� ������������ ����� ������������
//+------------------------------------------------------------------+
static int Slippage = 3;   // ����������� ���������������
//+------------------------------------------------------------------+
double OrdersToControl[ORDERS_TO_CONTROL][9];   // ������ � ��������� - ��� ������ � ��������
   //[0-������,1-�������,2-�������,3-��������][id ������][0-�������,1-�������][�����][0-��� ��������,1-�� ������][��������][0-��� ����������,1-�� ������][����������][MagicId]
   // ... ������ ����� �� 10 �������
//+------------------------------------------------------------------+
//| Functions                                                        |
//+------------------------------------------------------------------+
void OrderControlInit() {
   // �����������
   // �������� ������ ������ ����� � ��������
ArrayInitialize(OrdersToControl,0);
return;
}
//+------------------------------------------------------------------+
void OrderControlRelease() {
   // ����������
return;
}
//+------------------------------------------------------------------+
bool OrderControl() {
   // ��������� ������ - ��������/���������/�������� �������
for(int i=0;i<ORDERS_TO_CONTROL;i++) { // �� ����� ������� �������
   if(OrdersToControl[i][0]==0) continue; // ������ ������ - ������ �� ������
   // ���� �������
   int Rez = 0;
   switch(OrdersToControl[i][0]) {
      case OPEN_ORDER:
         // ������� �����
         if(OrdersToControl[i][2]==OP_BUY) Rez = CreateBuyOrder(OrdersToControl[i][3],OrdersToControl[i][4],OrdersToControl[i][5],OrdersToControl[i][6],OrdersToControl[i][7],OrdersToControl[i][8]);
         if(OrdersToControl[i][2]==OP_SELL) Rez = CreateSellOrder(OrdersToControl[i][3],OrdersToControl[i][4],OrdersToControl[i][5],OrdersToControl[i][6],OrdersToControl[i][7],OrdersToControl[i][8]);
         break;
      case CLOSE_ORDER:
         // ������� �����
         if(OrdersToControl[i][2]==OP_BUY) Rez = CloseBuyOrder(OrdersToControl[i][3],OrdersToControl[i][1]);
         if(OrdersToControl[i][2]==OP_SELL) Rez = CloseSellOrder(OrdersToControl[i][3],OrdersToControl[i][1]);
         break;
      case CORRECT_ORDER:
         // �������������� �����
         if(OrdersToControl[i][2]==OP_BUY) Rez = CorrectBuyOrder(OrdersToControl[i][4],OrdersToControl[i][5],OrdersToControl[i][6],OrdersToControl[i][7],OrdersToControl[i][1]);
         if(OrdersToControl[i][2]==OP_SELL) Rez = CorrectSellOrder(OrdersToControl[i][4],OrdersToControl[i][5],OrdersToControl[i][6],OrdersToControl[i][7],OrdersToControl[i][1]);
         break;
   }
   if((Rez==0)||(Rez==4108)||(Rez==1)) {
      // (��������� ������ �������) ��� (������ �� ���������� (�.�. ������ ������ ��������)) ��� (������ 1 - ������ �� ��������)
      // ������ ������� �� ��������� ������ �� ������� ������
      OrdersToControl[i][0] = 0;
      OrdersToControl[i][1] = 0;
      OrdersToControl[i][2] = 0;
      OrdersToControl[i][3] = 0;
      OrdersToControl[i][4] = 0;
      OrdersToControl[i][5] = 0;
      OrdersToControl[i][6] = 0;
      OrdersToControl[i][7] = 0;
      OrdersToControl[i][8] = 0;
   }
}
return(true);
}
//+------------------------------------------------------------------+
bool AddOrderToControl(int Command,int OrderId,int Type,double OrderVolume,bool MinSl,double Sl,bool MinTp,double Tp,int OrderMagicId) {
   // ���������� ����� ������� � ������ �������� �������
   // Command  OPEN_ORDER - ������� �����
   //          CLOSE_ORDER - ������� �����
   //          CORRECT_ORDER - �������� ������ ��������� ������
   // OrderId  Id ������ (OrderTicket() )
   // Type     OP_BUY - Buy �����
   //          OP_SELL - Sell �����
   // OrderVolume ����� ������
   // MinSl    true - ���������� ������������� ����������� ����-����
   //          false - ����� ��������� � ��������� Sl (���� � ���� ������ � Sl ������� 0.0 - ����-���� �� ����� ����������)
   // Sl       �������� ����-���� ���� ��������� �� ����������
   // MinTp    true - ���������� ������������� ����������� ����-������
   //          false - ����� ��������� � ��������� Tp (���� � ���� ������ � Tp ������� 0.0 - ����-������ �� ����� ����������)
   // Tp       �������� ����-������ ���� ��������� �� ����������
   // OrderMagicId   ���������� ������������� ������
bool Rez = false;
for(int i=0;i<ORDERS_TO_CONTROL;i++) { // �� ����� ������� �������
   if(OrdersToControl[i][0]==0) {
      // ���� ������ ������ ��� ��������� �������
      OrdersToControl[i][0] = Command;
      OrdersToControl[i][1] = OrderId;
      OrdersToControl[i][2] = Type;
      OrdersToControl[i][3] = OrderVolume;
      if(MinSl==true) OrdersToControl[i][4] = 0;
      else OrdersToControl[i][4] = 1;
      OrdersToControl[i][5] = Sl;
      if(MinTp==true) OrdersToControl[i][6] = 0;
      else OrdersToControl[i][6] = 1;
      OrdersToControl[i][7] = Tp;
      OrdersToControl[i][8] = OrderMagicId;
      Rez = true;
      break;
   }
}
if(Rez==false) Print("AddOrderToControl - ��� ����� ������!");
return(Rez);
}
//+------------------------------------------------------------------+
int CreateBuyOrder(double LotVolume,double MinStopLoss,double LotStopLoss,double MinTakeProfit,double LotTakeProfit,int LotMagic) {
   // �������� ������ �� �������
   // LotVolume - ����� ������
   // LotStopLoss,LotTakeProfit - ����-���� � ����-������ ��� ������ (���� 0 - �� �������)
   // MinStopLoss,MinTakeProfit - ���� 0 ��������� LotStopLoss � LotTakeProfit � ������������ ����������, 1 - ����� �� �� LotStopLoss � LotTakeProfit
   // LotMagic - ������������� ������ � �������� (���������� �����)
   // ���������� id ������
string LotSymbol = Symbol();     // ������ ��� �������� ����������� ����� (�������)
int LotSlippage = Slippage;      // ���������������
string LotComment = NULL;        // �����������
datetime LotExpiration = 0;      // ���� ��������� ����������� ������ (0 - ���������� ����������)
//color LotArrowColor = CLR_NONE;  // ���� ����������� ������� ������ �� ������� (�� ����������)
color LotArrowColor = Green;     // ���� ����������� ������� ������ �� �������
double LotPrice = Ask;           // ���� �������
double STVariation = MarketInfo(LotSymbol,MODE_STOPLEVEL)*Point+Point;  // ����������� ���������� ���� ��� ��������� StopLoss � TakeProfit (����� �� 1 ����� ������ ������������ �.�. �������� ���� ����� ������ � ����� �� ��������� - ��. 130)
if(MinStopLoss==0) LotStopLoss = Bid-STVariation;   // ����-����
if(MinTakeProfit==0) LotTakeProfit = Bid+STVariation;  // ����-������
int Rez = OrderSend(LotSymbol,OP_BUY,LotVolume,LotPrice,LotSlippage,LotStopLoss,LotTakeProfit,LotComment,LotMagic,LotExpiration,LotArrowColor);
if(Rez<0) {
   int Err = GetLastError();
   Print("���������� ������� ����� �� �������. ������: ",Err);
   return(Err);
}
return(0);
}
//+------------------------------------------------------------------+
int CreateSellOrder(double LotVolume,double MinStopLoss,double LotStopLoss,double MinTakeProfit,double LotTakeProfit,int LotMagic) {
   // �������� ������ �� �������
   // LotVolume - ����� ������
   // LotStopLoss,LotTakeProfit - ����-���� � ����-������ ��� ������ (���� 0 - �� �������)
   // MinStopLoss,MinTakeProfit - ���� 0 ��������� LotStopLoss � LotTakeProfit � ������������ ����������, 1 - ����� �� �� LotStopLoss � LotTakeProfit
   // LotMagic - ������������� ������ � �������� (���������� �����)
   // ���������� id ������
string LotSymbol = Symbol();     // ������ ��� �������� ����������� ����� (�������)
int LotSlippage = Slippage;      // ���������������
string LotComment = NULL;        // �����������
datetime LotExpiration = 0;      // ���� ��������� ����������� ������ (0 - ���������� ����������)
//color LotArrowColor = CLR_NONE;  // ���� ����������� ������� ������ �� ������� (�� ����������)
color LotArrowColor = Green;     // ���� ����������� ������� ������ �� �������
double LotPrice = Bid;           // ���� �������
double STVariation = MarketInfo(LotSymbol,MODE_STOPLEVEL)*Point+Point;  // ����������� ���������� ���� ��� ��������� StopLoss � TakeProfit (����� �� 1 ����� ������ ������������ �.�. �������� ���� ����� ������ � ����� �� ��������� - ��. 130)
if(MinStopLoss==0) LotStopLoss = Ask+STVariation;   // ����-����
if(MinTakeProfit==0) LotTakeProfit = Ask-STVariation;  // ����-������
int Rez = OrderSend(LotSymbol,OP_SELL,LotVolume,LotPrice,LotSlippage,LotStopLoss,LotTakeProfit,LotComment,LotMagic,LotExpiration,LotArrowColor);
if(Rez<0) {
   int Err = GetLastError();
   Print("���������� ������� ����� �� �������. ������: ",Err);
   return(Err);
}
return(0);
}
//+------------------------------------------------------------------+
int CloseBuyOrder(double LotVolume,int OrderId) {
   // �������� ������ �� �������
   // LotVolume - ����� ������
   // OrderId - Id ������ (��� �����)
int LotSlippage = Slippage;      // ���������������
//color LotArrowColor = CLR_NONE;  // ���� ����������� ������� ������ �� ������� (�� ����������)
color LotArrowColor = Maroon;    // ���� ����������� ������� ������ �� �������
double LotPrice = Bid;           // ���� ��������
bool Rez = OrderClose(OrderId,LotVolume,LotPrice,LotSlippage,LotArrowColor);
if(Rez==false) {
   int Err = GetLastError();
   Print("���������� ������� ����� �� ������� � "+OrderId+". ������: ",Err);
   return(Err);
}
return(0);
}
//+------------------------------------------------------------------+
int CloseSellOrder(double LotVolume,int OrderId) {
   // �������� ������ �� �������
   // LotVolume - ����� ������
   // OrderId - Id ������ (��� �����)
int LotSlippage = Slippage;      // ���������������
//color LotArrowColor = CLR_NONE;  // ���� ����������� ������� ������ �� ������� (�� ����������)
color LotArrowColor = Maroon;    // ���� ����������� ������� ������ �� �������
double LotPrice = Ask;           // ���� ��������
bool Rez = OrderClose(OrderId,LotVolume,LotPrice,LotSlippage,LotArrowColor);
if(Rez==false) {
   int Err = GetLastError();
   Print("���������� ������� ����� �� ������� � "+OrderId+". ������: ",Err);
   return(Err);
}
return(0);
}
//+------------------------------------------------------------------+
int CorrectBuyOrder(double MinStopLoss,double LotStopLoss,double MinTakeProfit,double LotTakeProfit,int OrderId) {
   // ������������� StopLoss � TakeProfit ������ �� �������
   // LotStopLoss,LotTakeProfit - ����-���� � ����-������ ��� ������ (���� 0 - �� �������)
   // MinStopLoss,MinTakeProfit - ���� 0 ��������� LotStopLoss � LotTakeProfit � ������������ ����������, 1 - ����� �� �� LotStopLoss � LotTakeProfit
   // OrderId - Id ������ (��� �����)
string LotSymbol = Symbol();     // ������ ��� �������� ����������� ����� (�������)
double STVariation = MarketInfo(LotSymbol,MODE_STOPLEVEL)*Point+Point;  // ����������� ���������� ���� ��� ��������� StopLoss � TakeProfit (����� �� 1 ����� ������ ������������ �.�. �������� ���� ����� ������ � ����� �� ��������� - ��. 130)
if(MinStopLoss==0) LotStopLoss = Bid-STVariation;     // ����-����
if(MinTakeProfit==0) LotTakeProfit = Bid+STVariation; // ����-������
double LotPrice = OrderOpenPrice(); // ���� ��������
color LotArrowColor = CLR_NONE;     // ���� ����������� ������� ������ �� ������� (�� ����������)
bool Rez = OrderModify(OrderId,LotPrice,LotStopLoss,LotTakeProfit,0,LotArrowColor);
if(Rez==false) {
   int Err = GetLastError();
   Print("���������� ���������������� ����� �� ������� � "+OrderId+". ������: ",Err);
   return(Err);
}
return(0);
}
//+------------------------------------------------------------------+
int CorrectSellOrder(double MinStopLoss,double LotStopLoss,double MinTakeProfit,double LotTakeProfit,int OrderId) {
   // ������������� StopLoss � TakeProfit ������ �� �������
   // LotStopLoss,LotTakeProfit - ����-���� � ����-������ ��� ������ (���� 0 - �� �������)
   // MinStopLoss,MinTakeProfit - ���� 0 ��������� LotStopLoss � LotTakeProfit � ������������ ����������, 1 - ����� �� �� LotStopLoss � LotTakeProfit
   // OrderId - Id ������ (��� �����)
string LotSymbol = Symbol();     // ������ ��� �������� ����������� ����� (�������)
double STVariation = MarketInfo(LotSymbol,MODE_STOPLEVEL)*Point+Point;  // ����������� ���������� ���� ��� ��������� StopLoss � TakeProfit (����� �� 1 ����� ������ ������������ �.�. �������� ���� ����� ������ � ����� �� ��������� - ��. 130)
if(MinStopLoss==0) LotStopLoss = Ask+STVariation;     // ����-����
if(MinTakeProfit==0) LotTakeProfit = Ask-STVariation; // ����-������
double LotPrice = OrderOpenPrice(); // ���� ��������
color LotArrowColor = CLR_NONE;     // ���� ����������� ������� ������ �� ������� (�� ����������)
bool Rez = OrderModify(OrderId,LotPrice,LotStopLoss,LotTakeProfit,0,LotArrowColor);
if(Rez==false) {
   int Err = GetLastError();
   Print("���������� ���������������� ����� �� ������� � "+OrderId+". ������: ",Err);
   return(Err);
}
return(0);
}
//+------------------------------------------------------------------+

