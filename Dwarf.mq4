//+------------------------------------------------------------------+
//|                                                        Dwarf.mq4 |
//|                                                           Nikita |
//|                                                  force_m@mail.ru |
//+------------------------------------------------------------------+
// Dwarf v.1.0
// Таймфрейм М1
// График USDEUR
// Масштаб - Фиксировать масштаб 1:1, подгоняем +/- когда линии баров становятся толщиной в 1 пиксель.
// График на весь экран. Масштаб нужно подгонять т.к. он влияет на отображение линий тенденции (на угол наклона).
//+------------------------------------------------------------------+
#property copyright "Nikita"
#property link      "force_m@mail.ru"
//+------------------------------------------------------------------+
#define EXPERT_ID 1000  // ID эксперта, считается в тысячах, чтобы последние 3 цифры не учитывались, они нужны для формирования MagicId в ордерах. Т.е. ID данного эксперта = 1
//+------------------------------------------------------------------+
#include <Common.mqh>            // Общие функции
#include <Graphic.mqh>           // Графические дополнения
#include <OrderControl.mqh>      // Для работы с ордерами
#include <LinearRegression.mqh>  // Построение линий линейной регрессии
//+------------------------------------------------------------------+
extern double WorkingLotVolume = 0.1;  // Объем лотов котоыре будем открывать-закрывать
extern int ShortTenBarsCount = 5;   // Короткая тенденция - Анализ ведем по X уже сформированным барам
extern int MiddleTenBarsCount = 45; // Средняя тенденция - Анализ ведем по X уже сформированным барам
extern int LongTenBarsCount = 90;   // Длинная тенденция - Анализ ведем по X уже сформированным барам
extern int MRealChangedBarsCount = 40;  // Если знак угла тенденции изменился и в течение этого кол-во баров не возвращается обратно - считаем что он уже точно изменился и не вернется (это не помехи)
extern int LCloseAngle = 20;  // Угол длинной тенденции при котором если она противоположна ордеру считаем что нужно ордер закрыть
extern int MovingSAngle = 0;   // Если Короткая тенденция отклоняется от горизонтали больше чем на этот угол - считаем что идет спад или рост, если внутри этого угла - движение ровное
extern int MovingMAngle = 0;   // Если Средняя тенденция отклоняется от горизонтали больше чем на этот угол - считаем что идет спад или рост, если внутри этого угла - движение ровное
extern int MovingLAngle = 20;   // Если Длинная тенденция отклоняется от горизонтали больше чем на этот угол - считаем что идет спад или рост, если внутри этого угла - движение ровное
extern int SlAddValue = 40;   // На данное кол-во поинтов увеличить значение минимального стоп-лосс
extern int OrderLife=0;   // Время жизни ордера в барах (по истечении которого ордер закрывается). 0 - бесконечно
extern int OrderAfterLife=0;   // Время после закрытия ордера, которое нельзя открывать новые ордера. 0 - не учитывается, 1 - можно открывать ордер
//+------------------------------------------------------------------+
static datetime LastBarTime;  // Статическая переменная для определения появления нового бара (хранит время появления последнего бара)
static int LotMagic; // Статическая переменная для хранения MagicID текущего открытого ордера
static int OrderTime;   // Статическая переменная для хранения оставшегося времени жизни OrderLife текущего открытого ордера
static int OrderAfterTime;   // Статическая переменная для хранения оставшегося времени OrderAfterLife
//+------------------------------------------------------------------+
int MovingS[2][4]; // Массив, описывающий направление короткой тенденции
   // [1-подьем,2-ровное,3-спад][длительность=кол-во баров][мощность=сумма(угол)][id] - текущее движение
   // [1-подьем,2-ровное,3-спад][длительность=кол-во баров][мощность=сумма(угол)][id] - направление дв-я, которое было до текущего
int MovingM[2][4]; // Массив, описывающий направление средней тенденции
   // [1-подьем,2-ровное,3-спад][длительность=кол-во баров][мощность=сумма(угол)][id] - суммарное (общее) направление движения
   // [1-подьем,2-ровное,3-спад][длительность=кол-во баров][мощность=сумма(угол)][id] - суммарное (общее) направление движения, которое было до текущего
int MovingL[2][4]; // Массив, описывающий направление длинной тенденции
   // [1-подьем,2-ровное,3-спад][длительность=кол-во баров][мощность=сумма(угол)][id] - суммарное (общее) направление движения
   // [1-подьем,2-ровное,3-спад][длительность=кол-во баров][мощность=сумма(угол)][id] - суммарное (общее) направление движения, которое было до текущего
//+------------------------------------------------------------------+
//| expert initialization function                                   |
//+------------------------------------------------------------------+
int init() {
   // При запуске эксперта
LotMagic = EXPERT_ID+1;
   // Для определения момента формирования нового бара
LastBarTime = 0;
   // Для контроля за временем жизни и послежизни ордеров
OrderTime=0;
OrderAfterTime=0;
   // Инициализация OrderControl
OrderControlInit();
   // Инициализация LinearRegression
LinearRegressionInit();
   // Обнулить массивы для хранения информации о движениях тенденций
ArrayInitialize(MovingS,0);
ArrayInitialize(MovingM,0);
ArrayInitialize(MovingL,0);
   // Окошко для вывода информации о угле короткой тенденции
//ObjectCreate("ShortTenLable",OBJ_LABEL,0,0,0,0,0);
//ObjectSet("ShortTenLable",OBJPROP_XDISTANCE,10);
//ObjectSet("ShortTenLable",OBJPROP_YDISTANCE,20);
//ObjectSetText("ShortTenLable","",8,"Courier",Gold);
   // Окошко для вывода информации о угле средней тенденции
ObjectCreate("MiddleTenLable",OBJ_LABEL,0,0,0,0,0);
ObjectSet("MiddleTenLable",OBJPROP_XDISTANCE,10);
ObjectSet("MiddleTenLable",OBJPROP_YDISTANCE,35);
ObjectSetText("MiddleTenLable","",8,"Courier",Gold);
   // Окошко для вывода информации о угле длинной тенденции
ObjectCreate("LongTenLable",OBJ_LABEL,0,0,0,0,0);
ObjectSet("LongTenLable",OBJPROP_XDISTANCE,10);
ObjectSet("LongTenLable",OBJPROP_YDISTANCE,50);
ObjectSetText("LongTenLable","",8,"Courier",Gold);
   // Окошко для вывода информации о коротком движении
//ObjectCreate("MoovingSLable0",OBJ_LABEL,0,0,0,0,0);
//ObjectSet("MoovingSLable0",OBJPROP_XDISTANCE,10);
//ObjectSet("MoovingSLable0",OBJPROP_YDISTANCE,65);
//ObjectSetText("MoovingSLable0","",8,"Courier",Gold);
//ObjectCreate("MoovingSLable1",OBJ_LABEL,0,0,0,0,0);
//ObjectSet("MoovingSLable1",OBJPROP_XDISTANCE,10);
//ObjectSet("MoovingSLable1",OBJPROP_YDISTANCE,80);
//ObjectSetText("MoovingSLable1","",8,"Courier",Gold);
   // Окошко для вывода информации о среднем движении
ObjectCreate("MoovingMLable0",OBJ_LABEL,0,0,0,0,0);
ObjectSet("MoovingMLable0",OBJPROP_XDISTANCE,10);
ObjectSet("MoovingMLable0",OBJPROP_YDISTANCE,95);
ObjectSetText("MoovingMLable0","",8,"Courier",Gold);
ObjectCreate("MoovingMLable1",OBJ_LABEL,0,0,0,0,0);
ObjectSet("MoovingMLable1",OBJPROP_XDISTANCE,10);
ObjectSet("MoovingMLable1",OBJPROP_YDISTANCE,110);
ObjectSetText("MoovingMLable1","",8,"Courier",Gold);
   // Окошко для вывода информации о длинном движении
ObjectCreate("MoovingLLable0",OBJ_LABEL,0,0,0,0,0);
ObjectSet("MoovingLLable0",OBJPROP_XDISTANCE,10);
ObjectSet("MoovingLLable0",OBJPROP_YDISTANCE,125);
ObjectSetText("MoovingLLable0","",8,"Courier",Gold);
ObjectCreate("MoovingLLable1",OBJ_LABEL,0,0,0,0,0);
ObjectSet("MoovingLLable1",OBJPROP_XDISTANCE,10);
ObjectSet("MoovingLLable1",OBJPROP_YDISTANCE,140);
ObjectSetText("MoovingLLable1","",8,"Courier",Gold);
   // Нарисовать прямую - начало работы советника
CreateStartLine("Dwarf");
return(0);
}
//+------------------------------------------------------------------+
//| expert deinitialization function                                 |
//+------------------------------------------------------------------+
int deinit() {
   // При выходе из эксперта
   // Деинициализация OrderControl
OrderControlRelease();
   // Деициализация LinearRegression
LinearRegressionRelease();
   // Линия начала работы
DeleteStartLine("Dwarf");
   // Окно короткой тенденции
//ObjectDelete("ShortTenLable");
ObjectDelete("MiddleTenLable");
ObjectDelete("LongTenLable");
   // Окна движения
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
   // Каждый тик
   // Обработать ордера, если есть команды на их обработку
OrderControl();
   // Проверим, сформировался-ли очередной бар
if(LastBarTime==Time[0]) return(0); // Новый бар еще не сформирован
LastBarTime = Time[0];  // Появился новый бар
   // Получить угол линейной регрессии для короткой тенденции
datetime Sx1 = 0;
datetime Sx2 = 0;
double Sy1 = 0.0;
double Sy2 = 0.0;
//double Sal = LinearRegression(ShortTenBarsCount,"ShortLinearRegressionLine",Blue,Sx1,Sx2,Sy1,Sy2);
double Sal = LinearRegression(ShortTenBarsCount,"",Blue,Sx1,Sx2,Sy1,Sy2);
   // Угол наклона короткой тенденции выводим на экран
//ObjectSetText("ShortTenLable","Угол короткой тенденции ("+ShortTenBarsCount+"-Bars): "+DoubleToStr(Sal,4),8,"Courier",Gold);
   // Получить угол линейной регрессии для средней тенденции
datetime Mx1 = 0;
datetime Mx2 = 0;
double My1 = 0.0;
double My2 = 0.0;
double Mal = LinearRegression(MiddleTenBarsCount,"MiddleLinearRegressionLine",Orange,Mx1,Mx2,My1,My2);
   // Угол наклона средней тенденции выводим на экран
ObjectSetText("MiddleTenLable","Угол средней тенденции ("+MiddleTenBarsCount+"-Bars): "+DoubleToStr(Mal,4),8,"Courier",Gold);
   // Получить угол линейной регрессии для длинной тенденции
datetime Lx1 = 0;
datetime Lx2 = 0;
double Ly1 = 0.0;
double Ly2 = 0.0;
double Lal = LinearRegression(LongTenBarsCount,"LongLinearRegressionLine",LawnGreen,Lx1,Lx2,Ly1,Ly2);
   // Угол наклона длинной тенденции выводим на экран
ObjectSetText("LongTenLable","Угол длинной тенденции ("+LongTenBarsCount+"-Bars): "+DoubleToStr(Lal,4),8,"Courier",Gold);
   // Проверяем изменения движений
int MovingSChanged = MOVING_NOT_CHANGED;
int MovingMChanged = MOVING_NOT_CHANGED;
int MovingLChanged = MOVING_NOT_CHANGED;
   // Заносим данные в массив движения Moving
   // Короткая тенденция
if(Sal>MovingSAngle) {
   // движение - подъем
   if(MovingS[0][0]!=MOVING_UP) {   // Изменение движения - начался подъем
      MovingSChanged = MOVING_CHANGED_TO_UP;
      // Сохранить старое движение во второй строке массива
      MovingS[1][0]=MovingS[0][0];
      MovingS[1][1]=MovingS[0][1];
      MovingS[1][2]=MovingS[0][2];
      MovingS[1][3]=MovingS[0][3];
      // Занести в 1 строку массива новое движение
      MovingS[0][0]=MOVING_UP;
      MovingS[0][1]=1;
      MovingS[0][2]=Sal;
      MovingS[0][3]++;
   }
   else {   // Движение продолжается
      MovingS[0][1]++;
      MovingS[0][2]+=Sal;
   }
}
else if(Sal<-MovingSAngle) {
   // движение - спад
   if(MovingS[0][0]!=MOVING_DOWN) {   // Изменение движения - начался спад
      MovingSChanged = MOVING_CHANGED_TO_DOWN;
      // Сохранить старое движение во второй строке массива
      MovingS[1][0]=MovingS[0][0];
      MovingS[1][1]=MovingS[0][1];
      MovingS[1][2]=MovingS[0][2];
      MovingS[1][3]=MovingS[0][3];
      // Занести в 1 строку массива новое движение
      MovingS[0][0]=MOVING_DOWN;
      MovingS[0][1]=1;
      MovingS[0][2]=Sal;
      MovingS[0][3]++;
   }
   else {   // Движение продолжается
      MovingS[0][1]++;
      MovingS[0][2]+=Sal;
   }
}
   // Средняя тенденция
if(Mal>MovingMAngle) {
   // движение - подъем
   if(MovingM[0][0]!=MOVING_UP) {   // Изменение движения - начался подъем
      MovingMChanged = MOVING_CHANGED_TO_UP;
      // Сохранить старое движение во второй строке массива
      MovingM[1][0]=MovingM[0][0];
      MovingM[1][1]=MovingM[0][1];
      MovingM[1][2]=MovingM[0][2];
      MovingM[1][3]=MovingM[0][3];
      // Занести в 1 строку массива новое движение
      MovingM[0][0]=MOVING_UP;
      MovingM[0][1]=1;
      MovingM[0][2]=Mal;
      MovingM[0][3]++;
   }
   else {   // Движение продолжается
      MovingM[0][1]++;
      MovingM[0][2]+=Mal;
   }
}
else if(Mal<-MovingMAngle) {
   // движение - спад
   if(MovingM[0][0]!=MOVING_DOWN) {   // Изменение движения - начался спад
      MovingMChanged = MOVING_CHANGED_TO_DOWN;
      // Сохранить старое движение во второй строке массива
      MovingM[1][0]=MovingM[0][0];
      MovingM[1][1]=MovingM[0][1];
      MovingM[1][2]=MovingM[0][2];
      MovingM[1][3]=MovingM[0][3];
      // Занести в 1 строку массива новое движение
      MovingM[0][0]=MOVING_DOWN;
      MovingM[0][1]=1;
      MovingM[0][2]=Mal;
      MovingM[0][3]++;
   }
   else {   // Движение продолжается
      MovingM[0][1]++;
      MovingM[0][2]+=Mal;
   }
}
   // Длинная тенденция
if(Lal>MovingLAngle) {
   // движение - подъем
   if(MovingL[0][0]!=MOVING_UP) {   // Изменение движения - начался подъем
      MovingLChanged = MOVING_CHANGED_TO_UP;
      // Сохранить старое движение во второй строке массива
      MovingL[1][0]=MovingL[0][0];
      MovingL[1][1]=MovingL[0][1];
      MovingL[1][2]=MovingL[0][2];
      MovingL[1][3]=MovingL[0][3];
      // Занести в 1 строку массива новое движение
      MovingL[0][0]=MOVING_UP;
      MovingL[0][1]=1;
      MovingL[0][2]=Lal;
      MovingL[0][3]++;
   }
   else {   // Движение продолжается
      MovingL[0][1]++;
      MovingL[0][2]+=Lal;
   }
}
else if(Lal<-MovingLAngle) {
   // движение - спад
   if(MovingL[0][0]!=MOVING_DOWN) {   // Изменение движения - начался спад
      MovingLChanged = MOVING_CHANGED_TO_DOWN;
      // Сохранить старое движение во второй строке массива
      MovingL[1][0]=MovingL[0][0];
      MovingL[1][1]=MovingL[0][1];
      MovingL[1][2]=MovingL[0][2];
      MovingL[1][3]=MovingL[0][3];
      // Занести в 1 строку массива новое движение
      MovingL[0][0]=MOVING_DOWN;
      MovingL[0][1]=1;
      MovingL[0][2]=Lal;
      MovingL[0][3]++;
   }
   else {   // Движение продолжается
      MovingL[0][1]++;
      MovingL[0][2]+=Lal;
   }
}
   // Информацию о движении - на экран
string MovingTxt[4] = {"???   ","подъем","ровное","спад  "};
//ObjectSetText("MoovingSLable0","Движение короткой тенденции       : "+MovingTxt[MovingS[0][0]]+" "+MovingS[0][1]+" "+MovingS[0][2]+" "+MovingS[0][3],8,"Courier",Gold);
//ObjectSetText("MoovingSLable1","Предыдущее дв-е короткой тенденции: "+MovingTxt[MovingS[1][0]]+" "+MovingS[1][1]+" "+MovingS[1][2]+" "+MovingS[1][3],8,"Courier",Gold);
ObjectSetText("MoovingMLable0","Движение средней тенденции        : "+MovingTxt[MovingM[0][0]]+" "+MovingM[0][1]+" "+MovingM[0][2]+" "+MovingM[0][3],8,"Courier",Gold);
ObjectSetText("MoovingMLable1","Предыдущее дв-е средней тенденции : "+MovingTxt[MovingM[1][0]]+" "+MovingM[1][1]+" "+MovingM[1][2]+" "+MovingM[1][3],8,"Courier",Gold);
ObjectSetText("MoovingLLable0","Движение длинной тенденции        : "+MovingTxt[MovingL[0][0]]+" "+MovingL[0][1]+" "+MovingL[0][2]+" "+MovingL[0][3],8,"Courier",Gold);
ObjectSetText("MoovingLLable1","Предыдущее дв-е длинной тенденции : "+MovingTxt[MovingL[1][0]]+" "+MovingL[1][1]+" "+MovingL[1][2]+" "+MovingL[1][3],8,"Courier",Gold);
/*
ObjectCreate(LastBarTime+"BarText",OBJ_TEXT,0,Time[1],Close[1]+Close[1]*0.15/100,0,0);
ObjectSetText(LastBarTime+"BarText",MovingTxt[MovingS[0][0]]+" "+MovingS[0][1]+" "+MovingS[0][2]+" "+MovingS[0][3],7,"Arial",Gold);
ObjectSet(LastBarTime+"BarText",OBJPROP_ANGLE,-90);
*/
   // Работа с ордерами
double STVariation = MarketInfo(Symbol(),MODE_STOPLEVEL)*Point+Point;  // Минимальное отклонение цены для установки StopLoss и TakeProfit (берем на 1 пункт больше минимального т.к. реальная цена может гулять)
double BuySl = Bid-(STVariation+Point*SlAddValue);  // Стоп-лосс для Buy-ордера
double SellSl = Ask+(STVariation+Point*SlAddValue);  // Стоп-лосс для Sell-ордера
   // Проверить - есть-ли открытые ордера
bool OrderCreated = false;
int CurrentOrder = 0;
int CurrentOrderType = OP_BUY;
bool Rez = false;
for(int i=0;i<OrdersTotal();i++) {// По всем открытым ордерам терминала
   // Если есть открытый ордер на данном графике с MagicId данного эксперта
   if((OrderSelect(i,SELECT_BY_POS)==true)&&(OrderSymbol()==Symbol())&&(OrderMagicNumber()==LotMagic)) {
      OrderCreated = true;
      CurrentOrder = OrderTicket();
      CurrentOrderType = OrderType();
      break;
   }
}
if(OrderCreated==false) {
   // Открытых ордеров нет
   // Проверить на возможность открытия ордера по времение OrderAfterLife
   if(OrderAfterTime>0) OrderAfterTime--;
   if(OrderAfterTime<=0) {
      // ПРОВЕРЯЕМ НА НЕОБХОДИМОСТЬ ОТКРЫТИЯ ОРДЕРА
      // (Длинная тенденция идет вверх) и (угол больше MovingLAngle) и (правая точка длинной тенденции выше текущего Ask не больше чем на STVariation - чтобы скомпенсировать резкие скачки) и (средняя идет вверх)-> создать Buy-ордер
      if(MovingL[0][0]==MOVING_UP&&Lal>=MovingLAngle&&(Ly1-Ask<STVariation)&&MovingM[0][0]==MOVING_UP) {
         LotMagic++;
         OrderTime=OrderLife; // Ордеру осталось жить OrderLife баров
         Rez = AddOrderToControl(OPEN_ORDER,0,OP_BUY,WorkingLotVolume,false,BuySl,false,0.0,LotMagic);
         if(Rez!=false) {
         // Создать прямые тенденций для информации
         ObjectCreate("BuyL-"+LotMagic,OBJ_TREND,0,Lx1,Ly1,Lx2,Ly2);
         ObjectSet("BuyL-"+LotMagic,OBJPROP_RAY,false);
         ObjectSet("BuyL-"+LotMagic,OBJPROP_COLOR,Aqua);
         ObjectSet("BuyL-"+LotMagic,OBJPROP_WIDTH,2);
         }
      }
      // (Длинная тенденция идет вниз) и (угол меньше MovingLAngle) и (правая точка длинной тенденции ниже текущего Bid не больше чем на STVariation - чтобы скомпенсировать резкие скачки) и (средняя идет вниз) -> создать Sell-ордер
      if(MovingL[0][0]==MOVING_DOWN&&Lal<=-MovingLAngle&&(Bid-Ly1<STVariation)&&MovingM[0][0]==MOVING_DOWN) {
         LotMagic++;
         OrderTime=OrderLife; // Ордеру осталось жить OrderLife баров
         Rez = AddOrderToControl(OPEN_ORDER,0,OP_SELL,WorkingLotVolume,false,SellSl,false,0.0,LotMagic);
         if(Rez!=false) {
         // Создать прямые тенденций для информации
         ObjectCreate("SellL-"+LotMagic,OBJ_TREND,0,Lx1,Ly1,Lx2,Ly2);
         ObjectSet("SellL-"+LotMagic,OBJPROP_RAY,false);
         ObjectSet("SellL-"+LotMagic,OBJPROP_COLOR,Aqua);
         ObjectSet("SellL-"+LotMagic,OBJPROP_WIDTH,2);
         }
      }
   }
}
else {
   // Есть открытый ордер -> Работа с открытым ордером
   OrderTime--;   // Время жизни ордера убавилось на 1
   // ПРОВЕРЯЕМ НА НЕОБХОДИМОСТЬ КОРРЕКТИРОВКИ ОРДЕРА
   bool SlMoving = true;
   if(CurrentOrderType==OP_BUY&&OrderStopLoss()>=BuySl) SlMoving = false;
   if(CurrentOrderType==OP_SELL&&OrderStopLoss()<=SellSl) SlMoving = false;
   // (Если кол-во баров для длинной тенденции >1 Тенденция не менялась) и (стоп-лосс изменяется не против движения) -> Корректировка ордера
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
   // ПРОВЕРЯЕМ НА НЕОБХОДИМОСТЬ ЗАКРЫТИЯ ОРДЕРА
   // Время жизни ордера == 1
   if((OrderTime==1)) {
      Rez = AddOrderToControl(CLOSE_ORDER,CurrentOrder,CurrentOrderType,WorkingLotVolume,true,0.0,false,0.0,LotMagic);
      OrderAfterTime = OrderAfterLife;
      ObjectCreate(LastBarTime+"BarText",OBJ_TEXT,0,Time[1],Close[1]+Close[1]*0.5/100,0,0);
      ObjectSetText(LastBarTime+"BarText","Время жизни ("+OrderLife+") истекло",7,"Arial",Gold);
      ObjectSet(LastBarTime+"BarText",OBJPROP_ANGLE,-90);
   }
   // Длинная тенденция противоположна ордеру и ее угол >= LCloseAngle
   if((Lal<=-LCloseAngle&&CurrentOrderType==OP_BUY)||(Lal>=LCloseAngle&&CurrentOrderType==OP_SELL)) {
      Rez = AddOrderToControl(CLOSE_ORDER,CurrentOrder,CurrentOrderType,WorkingLotVolume,true,0.0,false,0.0,LotMagic);
      OrderAfterTime = OrderAfterLife;
      ObjectCreate(LastBarTime+"BarText",OBJ_TEXT,0,Time[1],Close[1]+Close[1]*0.5/100,0,0);
      ObjectSetText(LastBarTime+"BarText","Дл. тенденция противоположна ордеру и ее угол >= LCloseAngle",7,"Arial",Gold);
      ObjectSet(LastBarTime+"BarText",OBJPROP_ANGLE,-90);
   }
   // средняя тенденция противоположна по знаку ордеру И удерживается больше MRealChangedBarsCount баров
   if(((Mal<0&&CurrentOrderType==OP_BUY)||(Mal>0&&CurrentOrderType==OP_SELL))&&MovingM[0][1]>=MRealChangedBarsCount) {
      Rez = AddOrderToControl(CLOSE_ORDER,CurrentOrder,CurrentOrderType,WorkingLotVolume,true,0.0,false,0.0,LotMagic);
      OrderAfterTime = OrderAfterLife;
      ObjectCreate(LastBarTime+"BarText",OBJ_TEXT,0,Time[1],Close[1]+Close[1]*0.5/100,0,0);
      ObjectSetText(LastBarTime+"BarText","Ср. тенденция противоположна ордеру и ужерживается "+MRealChangedBarsCount+" баров",7,"Arial",Gold);
      ObjectSet(LastBarTime+"BarText",OBJPROP_ANGLE,-90);
   }
}
return(0);
}
//+------------------------------------------------------------------+

