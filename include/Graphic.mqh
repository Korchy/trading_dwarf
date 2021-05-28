//+------------------------------------------------------------------+
//|                                                      Graphic.mq4 |
//|                                                    Force_Majeure |
//|                                                  force_m@mail.ru |
//+------------------------------------------------------------------+
#property copyright "Force_Majeure"
#property link      "force_m@mail.ru"
//+------------------------------------------------------------------+
//| defines                                                          |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Functions                                                        |
//+------------------------------------------------------------------+
bool CreateStartLine(string name) {
   // ������ ������������ ����� � ��������
ObjectCreate(name+"StartLine",OBJ_VLINE,0,Time[0],0,0,0);
ObjectSet(name+"StartLine",OBJPROP_COLOR,MediumSpringGreen);
ObjectSet(name+"StartLine",OBJPROP_WIDTH,2);
ObjectCreate(name+"StartText",OBJ_TEXT,0,Time[0],WindowPriceMin(0)+WindowPriceMin(0)*0.01/100,0,0);   // ����� ��������� ���� ���� �������� ����
ObjectSetText(name+"StartText",name+"Start",10,"Arial",MediumSpringGreen);
return(true);
}
//+------------------------------------------------------------------+
bool DeleteStartLine(string name) {
   // ������� ����� ������������ �������� StartLine
ObjectDelete(name+"StartLine");
ObjectDelete(name+"StartText");
return(true);
}
//+------------------------------------------------------------------+