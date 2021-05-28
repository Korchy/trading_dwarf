//+------------------------------------------------------------------+
//|                                                 OrderControl.mq4 |
//|                                                           Nikita |
//|                                                  force_m@mail.ru |
//+------------------------------------------------------------------+
// OrderControl - Вызывается каждый тик и обрабатывает команды на работу с ордерами
// занесенные в массив OrdersToControl. После обработки команда из массива удаляется.
// Заносится команда в массив вызовом функции AddOrderToControl.
//+------------------------------------------------------------------+
#property copyright "Nikita"
#property link      "force_m@mail.ru"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+
#define OPEN_ORDER      1  // Создать ордер
#define CLOSE_ORDER     2  // Закрыть ордер
#define CORRECT_ORDER   3  // Изменить ордер

#define ORDERS_TO_CONTROL  10 // Кол-во ордеров, которые одновременно можно обрабатывать
//+------------------------------------------------------------------+
static int Slippage = 3;   // Стандартное Проскальзывание
//+------------------------------------------------------------------+
double OrdersToControl[ORDERS_TO_CONTROL][9];   // Массив с командами - что делать с ордерами
   //[0-пустое,1-создать,2-закрыть,3-изменить][id ордера][0-покупка,1-продажа][объем][0-мин Стоплосс,1-СЛ указан][СтопЛосс][0-мин ТейкПрофит,1-ТП указан][ТейкПрофит][MagicId]
   // ... десять строк на 10 ордеров
//+------------------------------------------------------------------+
//| Functions                                                        |
//+------------------------------------------------------------------+
void OrderControlInit() {
   // Конструктор
   // Обнулить массив команд работ с ордерами
ArrayInitialize(OrdersToControl,0);
return;
}
//+------------------------------------------------------------------+
void OrderControlRelease() {
   // Деструктор
return;
}
//+------------------------------------------------------------------+
bool OrderControl() {
   // Обработка команд - Открытие/коррекция/закрытие ордеров
for(int i=0;i<ORDERS_TO_CONTROL;i++) { // По всему массиву ордеров
   if(OrdersToControl[i][0]==0) continue; // Пустая строка - ничего не делаем
   // Есть команда
   int Rez = 0;
   switch(OrdersToControl[i][0]) {
      case OPEN_ORDER:
         // Открыть ордер
         if(OrdersToControl[i][2]==OP_BUY) Rez = CreateBuyOrder(OrdersToControl[i][3],OrdersToControl[i][4],OrdersToControl[i][5],OrdersToControl[i][6],OrdersToControl[i][7],OrdersToControl[i][8]);
         if(OrdersToControl[i][2]==OP_SELL) Rez = CreateSellOrder(OrdersToControl[i][3],OrdersToControl[i][4],OrdersToControl[i][5],OrdersToControl[i][6],OrdersToControl[i][7],OrdersToControl[i][8]);
         break;
      case CLOSE_ORDER:
         // Закрыть ордер
         if(OrdersToControl[i][2]==OP_BUY) Rez = CloseBuyOrder(OrdersToControl[i][3],OrdersToControl[i][1]);
         if(OrdersToControl[i][2]==OP_SELL) Rez = CloseSellOrder(OrdersToControl[i][3],OrdersToControl[i][1]);
         break;
      case CORRECT_ORDER:
         // Корректировать ордер
         if(OrdersToControl[i][2]==OP_BUY) Rez = CorrectBuyOrder(OrdersToControl[i][4],OrdersToControl[i][5],OrdersToControl[i][6],OrdersToControl[i][7],OrdersToControl[i][1]);
         if(OrdersToControl[i][2]==OP_SELL) Rez = CorrectSellOrder(OrdersToControl[i][4],OrdersToControl[i][5],OrdersToControl[i][6],OrdersToControl[i][7],OrdersToControl[i][1]);
         break;
   }
   if((Rez==0)||(Rez==4108)||(Rez==1)) {
      // (Обработка ордера сделана) или (ордера не существует (м.б. закрыт другим способом)) или (ошибка 1 - ничего не изменено)
      // Убрать команду на обработку ордера из массива команд
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
   // Добавление новой команды в массив контроля ордеров
   // Command  OPEN_ORDER - открыть ордер
   //          CLOSE_ORDER - закрыть ордер
   //          CORRECT_ORDER - изменить данные открытого ордера
   // OrderId  Id ордера (OrderTicket() )
   // Type     OP_BUY - Buy ордер
   //          OP_SELL - Sell ордер
   // OrderVolume объем ордера
   // MinSl    true - подсчитать автоматически минимальный стоп-лосс
   //          false - брать указанное в параметре Sl (если в этом случае в Sl указать 0.0 - стоп-лосс не будет установлен)
   // Sl       величина стоп-лосс если указывать ее специально
   // MinTp    true - подсчитать автоматически минимальный тейк-профит
   //          false - брать указанное в параметре Tp (если в этом случае в Tp указать 0.0 - тейк-профит не будет установлен)
   // Tp       величина тейк-профит если указывать ее специально
   // OrderMagicId   Магический идентификатор ордера
bool Rez = false;
for(int i=0;i<ORDERS_TO_CONTROL;i++) { // По всему массиву ордеров
   if(OrdersToControl[i][0]==0) {
      // Есть пустая строка для занесения команды
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
if(Rez==false) Print("AddOrderToControl - все слоты заняты!");
return(Rez);
}
//+------------------------------------------------------------------+
int CreateBuyOrder(double LotVolume,double MinStopLoss,double LotStopLoss,double MinTakeProfit,double LotTakeProfit,int LotMagic) {
   // Создание ордера на покупку
   // LotVolume - обьем ордера
   // LotStopLoss,LotTakeProfit - стоп-лосс и тейк-профит для ордера (если 0 - не ставить)
   // MinStopLoss,MinTakeProfit - если 0 вычисляем LotStopLoss и LotTakeProfit с минимальными значениями, 1 - берем их из LotStopLoss и LotTakeProfit
   // LotMagic - идентификатор ордера к эксперту (магическое число)
   // Возвращает id ордера
string LotSymbol = Symbol();     // График для которого выполняется ордер (текущий)
int LotSlippage = Slippage;      // Проскальзывание
string LotComment = NULL;        // Комментарий
datetime LotExpiration = 0;      // Срок истечения отложенного ордера (0 - мгновенное исполнение)
//color LotArrowColor = CLR_NONE;  // Цвет отображения стрелки ордера на графике (не отображать)
color LotArrowColor = Green;     // Цвет отображения стрелки ордера на графике
double LotPrice = Ask;           // Цена покупки
double STVariation = MarketInfo(LotSymbol,MODE_STOPLEVEL)*Point+Point;  // Минимальное отклонение цены для установки StopLoss и TakeProfit (берем на 1 пункт больше минимального т.к. реальная цена может гулять и ордер не создастся - ош. 130)
if(MinStopLoss==0) LotStopLoss = Bid-STVariation;   // Стоп-лосс
if(MinTakeProfit==0) LotTakeProfit = Bid+STVariation;  // Тейк-профит
int Rez = OrderSend(LotSymbol,OP_BUY,LotVolume,LotPrice,LotSlippage,LotStopLoss,LotTakeProfit,LotComment,LotMagic,LotExpiration,LotArrowColor);
if(Rez<0) {
   int Err = GetLastError();
   Print("Невозможно создать ордер на покупку. Ошибка: ",Err);
   return(Err);
}
return(0);
}
//+------------------------------------------------------------------+
int CreateSellOrder(double LotVolume,double MinStopLoss,double LotStopLoss,double MinTakeProfit,double LotTakeProfit,int LotMagic) {
   // Создание ордера на продажу
   // LotVolume - обьем ордера
   // LotStopLoss,LotTakeProfit - стоп-лосс и тейк-профит для ордера (если 0 - не ставить)
   // MinStopLoss,MinTakeProfit - если 0 вычисляем LotStopLoss и LotTakeProfit с минимальными значениями, 1 - берем их из LotStopLoss и LotTakeProfit
   // LotMagic - идентификатор ордера к эксперту (магическое число)
   // Возвращает id ордера
string LotSymbol = Symbol();     // График для которого выполняется ордер (текущий)
int LotSlippage = Slippage;      // Проскальзывание
string LotComment = NULL;        // Комментарий
datetime LotExpiration = 0;      // Срок истечения отложенного ордера (0 - мгновенное исполнение)
//color LotArrowColor = CLR_NONE;  // Цвет отображения стрелки ордера на графике (не отображать)
color LotArrowColor = Green;     // Цвет отображения стрелки ордера на графике
double LotPrice = Bid;           // Цена покупки
double STVariation = MarketInfo(LotSymbol,MODE_STOPLEVEL)*Point+Point;  // Минимальное отклонение цены для установки StopLoss и TakeProfit (берем на 1 пункт больше минимального т.к. реальная цена может гулять и ордер не создастся - ош. 130)
if(MinStopLoss==0) LotStopLoss = Ask+STVariation;   // Стоп-лосс
if(MinTakeProfit==0) LotTakeProfit = Ask-STVariation;  // Тейк-профит
int Rez = OrderSend(LotSymbol,OP_SELL,LotVolume,LotPrice,LotSlippage,LotStopLoss,LotTakeProfit,LotComment,LotMagic,LotExpiration,LotArrowColor);
if(Rez<0) {
   int Err = GetLastError();
   Print("Невозможно создать ордер на продажу. Ошибка: ",Err);
   return(Err);
}
return(0);
}
//+------------------------------------------------------------------+
int CloseBuyOrder(double LotVolume,int OrderId) {
   // Закрытие ордера на покупку
   // LotVolume - обьем ордера
   // OrderId - Id ордера (его тикет)
int LotSlippage = Slippage;      // Проскальзывание
//color LotArrowColor = CLR_NONE;  // Цвет отображения стрелки ордера на графике (не отображать)
color LotArrowColor = Maroon;    // Цвет отображения стрелки ордера на графике
double LotPrice = Bid;           // Цена закрытия
bool Rez = OrderClose(OrderId,LotVolume,LotPrice,LotSlippage,LotArrowColor);
if(Rez==false) {
   int Err = GetLastError();
   Print("Невозможно закрыть ордер на покупку № "+OrderId+". Ошибка: ",Err);
   return(Err);
}
return(0);
}
//+------------------------------------------------------------------+
int CloseSellOrder(double LotVolume,int OrderId) {
   // Закрытие ордера на продажу
   // LotVolume - обьем ордера
   // OrderId - Id ордера (его тикет)
int LotSlippage = Slippage;      // Проскальзывание
//color LotArrowColor = CLR_NONE;  // Цвет отображения стрелки ордера на графике (не отображать)
color LotArrowColor = Maroon;    // Цвет отображения стрелки ордера на графике
double LotPrice = Ask;           // Цена закрытия
bool Rez = OrderClose(OrderId,LotVolume,LotPrice,LotSlippage,LotArrowColor);
if(Rez==false) {
   int Err = GetLastError();
   Print("Невозможно закрыть ордер на продажу № "+OrderId+". Ошибка: ",Err);
   return(Err);
}
return(0);
}
//+------------------------------------------------------------------+
int CorrectBuyOrder(double MinStopLoss,double LotStopLoss,double MinTakeProfit,double LotTakeProfit,int OrderId) {
   // Корректировка StopLoss и TakeProfit ордера на покупку
   // LotStopLoss,LotTakeProfit - стоп-лосс и тейк-профит для ордера (если 0 - не ставить)
   // MinStopLoss,MinTakeProfit - если 0 вычисляем LotStopLoss и LotTakeProfit с минимальными значениями, 1 - берем их из LotStopLoss и LotTakeProfit
   // OrderId - Id ордера (его тикет)
string LotSymbol = Symbol();     // График для которого выполняется ордер (текущий)
double STVariation = MarketInfo(LotSymbol,MODE_STOPLEVEL)*Point+Point;  // Минимальное отклонение цены для установки StopLoss и TakeProfit (берем на 1 пункт больше минимального т.к. реальная цена может гулять и ордер не создастся - ош. 130)
if(MinStopLoss==0) LotStopLoss = Bid-STVariation;     // Стоп-лосс
if(MinTakeProfit==0) LotTakeProfit = Bid+STVariation; // Тейк-профит
double LotPrice = OrderOpenPrice(); // Цена открытия
color LotArrowColor = CLR_NONE;     // Цвет отображения стрелки ордера на графике (не отображать)
bool Rez = OrderModify(OrderId,LotPrice,LotStopLoss,LotTakeProfit,0,LotArrowColor);
if(Rez==false) {
   int Err = GetLastError();
   Print("Невозможно откорректировать ордер на покупку № "+OrderId+". Ошибка: ",Err);
   return(Err);
}
return(0);
}
//+------------------------------------------------------------------+
int CorrectSellOrder(double MinStopLoss,double LotStopLoss,double MinTakeProfit,double LotTakeProfit,int OrderId) {
   // Корректировка StopLoss и TakeProfit ордера на покупку
   // LotStopLoss,LotTakeProfit - стоп-лосс и тейк-профит для ордера (если 0 - не ставить)
   // MinStopLoss,MinTakeProfit - если 0 вычисляем LotStopLoss и LotTakeProfit с минимальными значениями, 1 - берем их из LotStopLoss и LotTakeProfit
   // OrderId - Id ордера (его тикет)
string LotSymbol = Symbol();     // График для которого выполняется ордер (текущий)
double STVariation = MarketInfo(LotSymbol,MODE_STOPLEVEL)*Point+Point;  // Минимальное отклонение цены для установки StopLoss и TakeProfit (берем на 1 пункт больше минимального т.к. реальная цена может гулять и ордер не создастся - ош. 130)
if(MinStopLoss==0) LotStopLoss = Ask+STVariation;     // Стоп-лосс
if(MinTakeProfit==0) LotTakeProfit = Ask-STVariation; // Тейк-профит
double LotPrice = OrderOpenPrice(); // Цена открытия
color LotArrowColor = CLR_NONE;     // Цвет отображения стрелки ордера на графике (не отображать)
bool Rez = OrderModify(OrderId,LotPrice,LotStopLoss,LotTakeProfit,0,LotArrowColor);
if(Rez==false) {
   int Err = GetLastError();
   Print("Невозможно откорректировать ордер на продажу № "+OrderId+". Ошибка: ",Err);
   return(Err);
}
return(0);
}
//+------------------------------------------------------------------+

