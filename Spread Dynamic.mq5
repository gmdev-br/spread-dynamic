//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "© GM, 2020, 2021, 2022, 2023"
#property description "Spread Dynamic"
#property indicator_separate_window
#property indicator_buffers 61
#property indicator_plots   61

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum tipoSpread {
   Intraday,
   Diário,
   Semanal,
   Bisemanal,
   Mensal,
   Bimestral,
   Trimestral,
   Semestral,
   Anual,
   Bianual,
   Trienal,
   Quadrienal,
   Dinâmico
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ENUM_REG_SOURCE {
   Open,           // Open
   High,           // High
   Low,             // Low
   Close,         // Close
   Typical,     // Typical
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input datetime                               DefaultInitialDate = "2023.1.1 9:00:00"; // Data inicial padrão
input tipoSpread                             inputTipoSpread = Dinâmico;
input string                                 inputAtivo1 = "IND$N";
input ENUM_REG_SOURCE                        inputSource1 = Close;
input color                                  colorAtivo1 = clrRed;         // Cor ativo 1
input double                                 desvioAtivo1 = 0.15;
input double                                 referencia1 = 0;
input double                                 offset1 = 0;
input string                                 inputAtivo2 = "";
input ENUM_REG_SOURCE                        inputSource2 = Close;
input color                                  colorAtivo2 = clrLime;        // Cor ativo 2
input double                                 desvioAtivo2 = 0.25;
input double                                 referencia2 = 0;
input double                                 offset2 = 0;
input string                                 inputAtivo3 = "";
input ENUM_REG_SOURCE                        inputSource3 = Close;
input color                                  colorAtivo3 = clrDodgerBlue;        // Cor ativo 3
input double                                 desvioAtivo3 = 0.25;
input double                                 referencia3 = 0;
input double                                 offset3 = 0;
input int                                    espessura_linha = 2;              // Espessura da linha
input int                                    WaitMilliseconds = 2000;           // Timer (milliseconds) for recalculation

input bool                                   exibeCurva = true;
input bool                                   debug = false;
input bool                                   autoCapitalLetters = true;
input double                                 escalaMax = 0;
input double                                 escalaMin = 0;
input bool                                   showPrice = false;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double    spreadBuffer[];
double    bufferAtivo1[];
double    bufferAtivo2[];
double    bufferAtivo3[];
double    bufferAtivo23[];
double    bufferShowPrice1[], bufferShowPrice2[], bufferShowPrice3[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double regChannelBufferAtivo1[], regChannelBufferAtivo2[], regChannelBufferAtivo3[], regChannelBufferAtivo23[];

double regChannelAtivo1_1[], regChannelAtivo1_2[], regChannelAtivo1_3[], regChannelAtivo1_4[], regChannelAtivo1_5[], regChannelAtivo1_6[];
double regChannelAtivo1_7[], regChannelAtivo1_8[], regChannelAtivo1_9[], regChannelAtivo1_10[], regChannelAtivo1_11[], regChannelAtivo1_12[];

double regChannelAtivo2_1[], regChannelAtivo2_2[], regChannelAtivo2_3[], regChannelAtivo2_4[], regChannelAtivo2_5[], regChannelAtivo2_6[];
double regChannelAtivo2_7[], regChannelAtivo2_8[], regChannelAtivo2_9[], regChannelAtivo2_10[], regChannelAtivo2_11[], regChannelAtivo2_12[];

double regChannelAtivo3_1[], regChannelAtivo3_2[], regChannelAtivo3_3[], regChannelAtivo3_4[], regChannelAtivo3_5[], regChannelAtivo3_6[];
double regChannelAtivo3_7[], regChannelAtivo3_8[], regChannelAtivo3_9[], regChannelAtivo3_10[], regChannelAtivo3_11[], regChannelAtivo3_12[];

double regChannelSpread_1[], regChannelSpread_2[], regChannelSpread_3[], regChannelSpread_4[], regChannelSpread_5[], regChannelSpread_6[];
double regChannelSpread_7[], regChannelSpread_8[], regChannelSpread_9[], regChannelSpread_10[], regChannelSpread_11[], regChannelSpread_12[];

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double A, B, stdev;
datetime data_inicial;
int barFrom;

string ativo1, ativo2, ativo3;

long totalRates;
int rateCount;
color cor = clrDimGray;

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {

   ativo1 = inputAtivo1;
   ativo2 = inputAtivo2;
   ativo3 = inputAtivo3;

   if (autoCapitalLetters) {
      StringToUpper(ativo1);
      StringToUpper(ativo2);
      StringToUpper(ativo3);
   }

   if (ativo1 == "" && ativo2 == "" && ativo3 == "")
      ativo1 = Symbol();

   ObjectDelete(0, "spread_from_line");

   for(int i = 0; i <= 60; i++) {
      PlotIndexSetInteger(i, PLOT_DRAW_TYPE, DRAW_LINE);
      PlotIndexSetDouble(i, PLOT_EMPTY_VALUE, 0.0);
      PlotIndexSetInteger(i, PLOT_SHOW_DATA, false);       //--- repeat for each plot
   }

   if (ativo1 != "") PlotIndexSetInteger(58, PLOT_SHOW_DATA, true);
   if (ativo2 != "") PlotIndexSetInteger(59, PLOT_SHOW_DATA, true);
   if (ativo3 != "") PlotIndexSetInteger(60, PLOT_SHOW_DATA, true);
   
   PlotIndexSetInteger(58, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(59, PLOT_DRAW_TYPE, DRAW_LINE);
   PlotIndexSetInteger(60, PLOT_DRAW_TYPE, DRAW_LINE);

//ChartSetInteger(0, CHART_SHIFT, 1);
//ChartSetDouble(0, CHART_SHIFT_SIZE, 10);

//PlotIndexSetInteger(58, PLOT_SHOW_DATA, true);

   SetIndexBuffer(0, spreadBuffer, INDICATOR_DATA);
   PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);

   SetIndexBuffer(1, bufferAtivo1, INDICATOR_DATA);
   SetIndexBuffer(2, bufferAtivo2, INDICATOR_DATA);
   SetIndexBuffer(3, bufferAtivo3, INDICATOR_DATA);

   PlotIndexSetInteger(0, PLOT_LINE_WIDTH, espessura_linha);
   PlotIndexSetInteger(1, PLOT_LINE_WIDTH, espessura_linha);
   PlotIndexSetInteger(2, PLOT_LINE_WIDTH, espessura_linha);
   PlotIndexSetInteger(3, PLOT_LINE_WIDTH, espessura_linha);
   PlotIndexSetInteger(4, PLOT_LINE_WIDTH, espessura_linha);

   PlotIndexSetString(1, PLOT_LABEL, ativo1);
   PlotIndexSetString(2, PLOT_LABEL, ativo2);
   PlotIndexSetString(3, PLOT_LABEL, ativo3);

   PlotIndexSetString(6, PLOT_LABEL, ativo1);
   PlotIndexSetString(7, PLOT_LABEL, ativo2);
   PlotIndexSetString(8, PLOT_LABEL, ativo3);

   PlotIndexSetInteger(1, PLOT_LINE_COLOR, 0, colorAtivo1);
   PlotIndexSetInteger(2, PLOT_LINE_COLOR, 0, colorAtivo2);
   PlotIndexSetInteger(3, PLOT_LINE_COLOR, 0, colorAtivo3);

   PlotIndexSetInteger(6, PLOT_LINE_COLOR, 0, colorAtivo1);
   PlotIndexSetInteger(7, PLOT_LINE_COLOR, 0, colorAtivo2);
   PlotIndexSetInteger(8, PLOT_LINE_COLOR, 0, colorAtivo3);

   PlotIndexSetString(58, PLOT_LABEL, inputAtivo1 + " - " + getSourceName(inputSource1));
   PlotIndexSetString(59, PLOT_LABEL, inputAtivo2 + " - " + getSourceName(inputSource2));
   PlotIndexSetString(60, PLOT_LABEL, inputAtivo3 + " - " + getSourceName(inputSource3));

   ArrayInitialize(bufferAtivo1, 0);
   ArrayInitialize(bufferAtivo2, 0);
   ArrayInitialize(bufferAtivo3, 0);
   ArrayInitialize(bufferAtivo23, 0);
   ArrayInitialize(bufferShowPrice1, 0);
   ArrayInitialize(bufferShowPrice2, 0);
   ArrayInitialize(bufferShowPrice3, 0);

   ArrayInitialize(regChannelBufferAtivo1, 0);
   ArrayInitialize(regChannelBufferAtivo2, 0);
   ArrayInitialize(regChannelBufferAtivo3, 0);

   ArrayInitialize(regChannelAtivo1_1, 0);
   ArrayInitialize(regChannelAtivo1_2, 0);
   ArrayInitialize(regChannelAtivo1_3, 0);
   ArrayInitialize(regChannelAtivo1_4, 0);
   ArrayInitialize(regChannelAtivo1_5, 0);
   ArrayInitialize(regChannelAtivo1_6, 0);
   ArrayInitialize(regChannelAtivo1_7, 0);
   ArrayInitialize(regChannelAtivo1_8, 0);
   ArrayInitialize(regChannelAtivo1_9, 0);
   ArrayInitialize(regChannelAtivo1_10, 0);
   ArrayInitialize(regChannelAtivo1_11, 0);
   ArrayInitialize(regChannelAtivo1_12, 0);

   ArrayInitialize(regChannelAtivo2_1, 0);
   ArrayInitialize(regChannelAtivo2_2, 0);
   ArrayInitialize(regChannelAtivo2_3, 0);
   ArrayInitialize(regChannelAtivo2_4, 0);
   ArrayInitialize(regChannelAtivo2_5, 0);
   ArrayInitialize(regChannelAtivo2_6, 0);
   ArrayInitialize(regChannelAtivo2_7, 0);
   ArrayInitialize(regChannelAtivo2_8, 0);
   ArrayInitialize(regChannelAtivo2_9, 0);
   ArrayInitialize(regChannelAtivo2_10, 0);
   ArrayInitialize(regChannelAtivo2_11, 0);
   ArrayInitialize(regChannelAtivo2_12, 0);

   ArrayInitialize(regChannelAtivo3_1, 0);
   ArrayInitialize(regChannelAtivo3_2, 0);
   ArrayInitialize(regChannelAtivo3_3, 0);
   ArrayInitialize(regChannelAtivo3_4, 0);
   ArrayInitialize(regChannelAtivo3_5, 0);
   ArrayInitialize(regChannelAtivo3_6, 0);
   ArrayInitialize(regChannelAtivo3_7, 0);
   ArrayInitialize(regChannelAtivo3_8, 0);
   ArrayInitialize(regChannelAtivo3_9, 0);
   ArrayInitialize(regChannelAtivo3_10, 0);
   ArrayInitialize(regChannelAtivo3_11, 0);
   ArrayInitialize(regChannelAtivo3_12, 0);

   SetIndexBuffer(6, regChannelBufferAtivo1, INDICATOR_DATA);
   SetIndexBuffer(7, regChannelBufferAtivo2, INDICATOR_DATA);
   SetIndexBuffer(8, regChannelBufferAtivo3, INDICATOR_DATA);

   int nSpread = 10;

   int nInd = nSpread + 12;
   SetIndexBuffer(nInd, regChannelAtivo1_1, INDICATOR_DATA);
   SetIndexBuffer(nInd + 1, regChannelAtivo1_2, INDICATOR_DATA);
   SetIndexBuffer(nInd + 2, regChannelAtivo1_3, INDICATOR_DATA);
   SetIndexBuffer(nInd + 3, regChannelAtivo1_4, INDICATOR_DATA);
   SetIndexBuffer(nInd + 4, regChannelAtivo1_5, INDICATOR_DATA);
   SetIndexBuffer(nInd + 5, regChannelAtivo1_6, INDICATOR_DATA);
   SetIndexBuffer(nInd + 6, regChannelAtivo1_7, INDICATOR_DATA);
   SetIndexBuffer(nInd + 7, regChannelAtivo1_8, INDICATOR_DATA);
   SetIndexBuffer(nInd + 8, regChannelAtivo1_9, INDICATOR_DATA);
   SetIndexBuffer(nInd + 9, regChannelAtivo1_10, INDICATOR_DATA);
   SetIndexBuffer(nInd + 10, regChannelAtivo1_11, INDICATOR_DATA);
   SetIndexBuffer(nInd + 11, regChannelAtivo1_12, INDICATOR_DATA);

   int nDol = nSpread + 24;
   SetIndexBuffer(nDol, regChannelAtivo2_1, INDICATOR_DATA);
   SetIndexBuffer(nDol + 1, regChannelAtivo2_2, INDICATOR_DATA);
   SetIndexBuffer(nDol + 2, regChannelAtivo2_3, INDICATOR_DATA);
   SetIndexBuffer(nDol + 3, regChannelAtivo2_4, INDICATOR_DATA);
   SetIndexBuffer(nDol + 4, regChannelAtivo2_5, INDICATOR_DATA);
   SetIndexBuffer(nDol + 5, regChannelAtivo2_6, INDICATOR_DATA);
   SetIndexBuffer(nDol + 6, regChannelAtivo2_7, INDICATOR_DATA);
   SetIndexBuffer(nDol + 7, regChannelAtivo2_8, INDICATOR_DATA);
   SetIndexBuffer(nDol + 8, regChannelAtivo2_9, INDICATOR_DATA);
   SetIndexBuffer(nDol + 9, regChannelAtivo2_10, INDICATOR_DATA);
   SetIndexBuffer(nDol + 10, regChannelAtivo2_11, INDICATOR_DATA);
   SetIndexBuffer(nDol + 11, regChannelAtivo2_12, INDICATOR_DATA);

   int nDi = nSpread + 36;
   SetIndexBuffer(nDi, regChannelAtivo3_1, INDICATOR_DATA);
   SetIndexBuffer(nDi + 1, regChannelAtivo3_2, INDICATOR_DATA);
   SetIndexBuffer(nDi + 2, regChannelAtivo3_3, INDICATOR_DATA);
   SetIndexBuffer(nDi + 3, regChannelAtivo3_4, INDICATOR_DATA);
   SetIndexBuffer(nDi + 4, regChannelAtivo3_5, INDICATOR_DATA);
   SetIndexBuffer(nDi + 5, regChannelAtivo3_6, INDICATOR_DATA);
   SetIndexBuffer(nDi + 6, regChannelAtivo3_7, INDICATOR_DATA);
   SetIndexBuffer(nDi + 7, regChannelAtivo3_8, INDICATOR_DATA);
   SetIndexBuffer(nDi + 8, regChannelAtivo3_9, INDICATOR_DATA);
   SetIndexBuffer(nDi + 9, regChannelAtivo3_10, INDICATOR_DATA);
   SetIndexBuffer(nDi + 10, regChannelAtivo3_11, INDICATOR_DATA);
   SetIndexBuffer(nDi + 11, regChannelAtivo3_12, INDICATOR_DATA);

   SetIndexBuffer(nDi + 12, bufferShowPrice1, INDICATOR_DATA);
   SetIndexBuffer(nDi + 13, bufferShowPrice2, INDICATOR_DATA);
   SetIndexBuffer(nDi + 14, bufferShowPrice3, INDICATOR_DATA);

   ArraySetAsSeries(bufferAtivo1, true);
   ArraySetAsSeries(bufferAtivo2, true);
   ArraySetAsSeries(bufferAtivo3, true);
   ArraySetAsSeries(bufferShowPrice1, true);
   ArraySetAsSeries(bufferShowPrice2, true);
   ArraySetAsSeries(bufferShowPrice3, true);

   ArraySetAsSeries(regChannelBufferAtivo1, true);
   ArraySetAsSeries(regChannelBufferAtivo2, true);
   ArraySetAsSeries(regChannelBufferAtivo3, true);

   ArraySetAsSeries(regChannelAtivo1_1, true);
   ArraySetAsSeries(regChannelAtivo1_2, true);
   ArraySetAsSeries(regChannelAtivo1_3, true);
   ArraySetAsSeries(regChannelAtivo1_4, true);
   ArraySetAsSeries(regChannelAtivo1_5, true);
   ArraySetAsSeries(regChannelAtivo1_6, true);
   ArraySetAsSeries(regChannelAtivo1_7, true);
   ArraySetAsSeries(regChannelAtivo1_8, true);
   ArraySetAsSeries(regChannelAtivo1_9, true);
   ArraySetAsSeries(regChannelAtivo1_10, true);
   ArraySetAsSeries(regChannelAtivo1_11, true);
   ArraySetAsSeries(regChannelAtivo1_12, true);

   ArraySetAsSeries(regChannelAtivo2_1, true);
   ArraySetAsSeries(regChannelAtivo2_2, true);
   ArraySetAsSeries(regChannelAtivo2_3, true);
   ArraySetAsSeries(regChannelAtivo2_4, true);
   ArraySetAsSeries(regChannelAtivo2_5, true);
   ArraySetAsSeries(regChannelAtivo2_6, true);
   ArraySetAsSeries(regChannelAtivo2_7, true);
   ArraySetAsSeries(regChannelAtivo2_8, true);
   ArraySetAsSeries(regChannelAtivo2_9, true);
   ArraySetAsSeries(regChannelAtivo2_10, true);
   ArraySetAsSeries(regChannelAtivo2_11, true);
   ArraySetAsSeries(regChannelAtivo2_12, true);

   ArraySetAsSeries(regChannelAtivo3_1, true);
   ArraySetAsSeries(regChannelAtivo3_2, true);
   ArraySetAsSeries(regChannelAtivo3_3, true);
   ArraySetAsSeries(regChannelAtivo3_4, true);
   ArraySetAsSeries(regChannelAtivo3_5, true);
   ArraySetAsSeries(regChannelAtivo3_6, true);
   ArraySetAsSeries(regChannelAtivo3_7, true);
   ArraySetAsSeries(regChannelAtivo3_8, true);
   ArraySetAsSeries(regChannelAtivo3_9, true);
   ArraySetAsSeries(regChannelAtivo3_10, true);
   ArraySetAsSeries(regChannelAtivo3_11, true);
   ArraySetAsSeries(regChannelAtivo3_12, true);

   cor = clrDimGray;
   PlotIndexSetInteger(nInd, PLOT_LINE_COLOR, 0, colorAtivo1);
   PlotIndexSetInteger(nInd + 1, PLOT_LINE_COLOR, 0, colorAtivo1);
   PlotIndexSetInteger(nInd + 2, PLOT_LINE_COLOR, 0, colorAtivo1);
   PlotIndexSetInteger(nInd + 3, PLOT_LINE_COLOR, 0, colorAtivo1);
   PlotIndexSetInteger(nInd + 4, PLOT_LINE_COLOR, 0, colorAtivo1);
   PlotIndexSetInteger(nInd + 5, PLOT_LINE_COLOR, 0, colorAtivo1);
   PlotIndexSetInteger(nInd + 6, PLOT_LINE_COLOR, 0, colorAtivo1);
   PlotIndexSetInteger(nInd + 7, PLOT_LINE_COLOR, 0, colorAtivo1);
   PlotIndexSetInteger(nInd + 8, PLOT_LINE_COLOR, 0, colorAtivo1);
   PlotIndexSetInteger(nInd + 9, PLOT_LINE_COLOR, 0, colorAtivo1);
   PlotIndexSetInteger(nInd + 10, PLOT_LINE_COLOR, 0, colorAtivo1);
   PlotIndexSetInteger(nInd + 11, PLOT_LINE_COLOR, 0, colorAtivo1);

   PlotIndexSetInteger(nDol, PLOT_LINE_COLOR, 0, colorAtivo2);
   PlotIndexSetInteger(nDol + 1, PLOT_LINE_COLOR, 0, colorAtivo2);
   PlotIndexSetInteger(nDol + 2, PLOT_LINE_COLOR, 0, colorAtivo2);
   PlotIndexSetInteger(nDol + 3, PLOT_LINE_COLOR, 0, colorAtivo2);
   PlotIndexSetInteger(nDol + 4, PLOT_LINE_COLOR, 0, colorAtivo2);
   PlotIndexSetInteger(nDol + 5, PLOT_LINE_COLOR, 0, colorAtivo2);
   PlotIndexSetInteger(nDol + 6, PLOT_LINE_COLOR, 0, colorAtivo2);
   PlotIndexSetInteger(nDol + 7, PLOT_LINE_COLOR, 0, colorAtivo2);
   PlotIndexSetInteger(nDol + 8, PLOT_LINE_COLOR, 0, colorAtivo2);
   PlotIndexSetInteger(nDol + 9, PLOT_LINE_COLOR, 0, colorAtivo2);
   PlotIndexSetInteger(nDol + 10, PLOT_LINE_COLOR, 0, colorAtivo2);
   PlotIndexSetInteger(nDol + 11, PLOT_LINE_COLOR, 0, colorAtivo2);

   PlotIndexSetInteger(nDi, PLOT_LINE_COLOR, 0, colorAtivo3);
   PlotIndexSetInteger(nDi + 1, PLOT_LINE_COLOR, 0, colorAtivo3);
   PlotIndexSetInteger(nDi + 2, PLOT_LINE_COLOR, 0, colorAtivo3);
   PlotIndexSetInteger(nDi + 3, PLOT_LINE_COLOR, 0, colorAtivo3);
   PlotIndexSetInteger(nDi + 4, PLOT_LINE_COLOR, 0, colorAtivo3);
   PlotIndexSetInteger(nDi + 5, PLOT_LINE_COLOR, 0, colorAtivo3);
   PlotIndexSetInteger(nDi + 6, PLOT_LINE_COLOR, 0, colorAtivo3);
   PlotIndexSetInteger(nDi + 7, PLOT_LINE_COLOR, 0, colorAtivo3);
   PlotIndexSetInteger(nDi + 8, PLOT_LINE_COLOR, 0, colorAtivo3);
   PlotIndexSetInteger(nDi + 9, PLOT_LINE_COLOR, 0, colorAtivo3);
   PlotIndexSetInteger(nDi + 10, PLOT_LINE_COLOR, 0, colorAtivo3);
   PlotIndexSetInteger(nDi + 11, PLOT_LINE_COLOR, 0, colorAtivo3);

   PlotIndexSetInteger(nDi + 12, PLOT_LINE_COLOR, 0, colorAtivo1);
   PlotIndexSetInteger(nDi + 13, PLOT_LINE_COLOR, 0, colorAtivo2);
   PlotIndexSetInteger(nDi + 14, PLOT_LINE_COLOR, 0, colorAtivo3);

   PlotIndexSetInteger(5, PLOT_LINE_WIDTH, espessura_linha + 1);
   PlotIndexSetInteger(6, PLOT_LINE_WIDTH, espessura_linha + 1);
   PlotIndexSetInteger(7, PLOT_LINE_WIDTH, espessura_linha + 1);
   PlotIndexSetInteger(8, PLOT_LINE_WIDTH, espessura_linha + 1);
   PlotIndexSetInteger(9, PLOT_LINE_WIDTH, espessura_linha + 1);

   PlotIndexSetInteger(58, PLOT_LINE_WIDTH, espessura_linha + 1);
   PlotIndexSetInteger(59, PLOT_LINE_WIDTH, espessura_linha + 1);
   PlotIndexSetInteger(60, PLOT_LINE_WIDTH, espessura_linha + 1);

   for(int i = 10; i < 58; i++) {
      PlotIndexSetInteger(i, PLOT_LINE_STYLE, STYLE_DOT);
   }

   PlotIndexSetInteger(58, PLOT_LINE_STYLE, STYLE_SOLID);
   PlotIndexSetInteger(59, PLOT_LINE_STYLE, STYLE_SOLID);
   PlotIndexSetInteger(60, PLOT_LINE_STYLE, STYLE_SOLID);

   data_inicial = DefaultInitialDate;

   MqlDateTime time;
   TimeToStruct(TimeCurrent(), time);
   int anoAtual = time.year;
   int anoAlvo;
   datetime dataAlvo;
   time.mon = 1;
   time.day = 1;
   time.hour = 0;
   time.min = 0;
   time.sec = 0;

   if (inputTipoSpread == Intraday) {
      data_inicial = iTime(NULL, PERIOD_CURRENT, 0);
   } else if (inputTipoSpread == Diário) {
      data_inicial = iTime(NULL, PERIOD_D1, 0);
   } else if (inputTipoSpread == Semanal) {
      data_inicial = iTime(NULL, PERIOD_W1, 0);
   } else if (inputTipoSpread == Bisemanal) {
      data_inicial = iTime(NULL, PERIOD_W1, 1);
   } else if (inputTipoSpread == Mensal) {
      data_inicial = iTime(NULL, PERIOD_MN1, 0);
   } else if (inputTipoSpread == Bimestral) {
      data_inicial = iTime(NULL, PERIOD_MN1, 1);
   } else if (inputTipoSpread == Trimestral) {
      data_inicial = iTime(NULL, PERIOD_MN1, 2);
   } else if (inputTipoSpread == Semestral) {
      data_inicial = iTime(NULL, PERIOD_MN1, 5);
   } else if (inputTipoSpread == Anual) {
      time.year = anoAtual;
      data_inicial = dataAlvo;
   } else if (inputTipoSpread == Bianual) {
      anoAlvo = anoAtual - 1;
      time.year = anoAlvo;
      dataAlvo = StructToTime(time);
      data_inicial = dataAlvo;
   } else if (inputTipoSpread == Trienal) {
      anoAlvo = anoAtual - 2;
      time.year = anoAlvo;
      dataAlvo = StructToTime(time);
      data_inicial = dataAlvo;
   } else if (inputTipoSpread == Quadrienal) {
      anoAlvo = anoAtual - 3;
      time.year = anoAlvo;
      dataAlvo = StructToTime(time);
      data_inicial = dataAlvo;
   } else if (inputTipoSpread == Dinâmico) {
      data_inicial = DefaultInitialDate;
   }

   barFrom = iBarShift(NULL, PERIOD_CURRENT, data_inicial);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if (inputTipoSpread == Dinâmico) {
      DrawVLine("spread_from_line", DefaultInitialDate, clrLime, 1, STYLE_DOT, false, true, true, 500);
   } else {
      ObjectDelete(1, "spread_from_line");
   }

   PlotIndexSetInteger(0, PLOT_DRAW_TYPE, DRAW_NONE);
   PlotIndexSetInteger(1, PLOT_DRAW_TYPE, DRAW_NONE);
   PlotIndexSetInteger(2, PLOT_DRAW_TYPE, DRAW_NONE);
   PlotIndexSetInteger(3, PLOT_DRAW_TYPE, DRAW_NONE);
   PlotIndexSetInteger(4, PLOT_DRAW_TYPE, DRAW_NONE);
   PlotIndexSetInteger(5, PLOT_DRAW_TYPE, DRAW_NONE);
   PlotIndexSetInteger(9, PLOT_DRAW_TYPE, DRAW_NONE);

   IndicatorSetInteger(INDICATOR_DIGITS, 2);
   IndicatorSetString(INDICATOR_SHORTNAME, "Spread");

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   _updateTimer = new MillisecondTimer(WaitMilliseconds, false);
   _lastOK = false;
   CheckTimer();

   return(INIT_SUCCEEDED);

}

//+------------------------------------------------------------------+
//| Relative Strength Index                                          |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total, const int prev_calculated, const int begin, const double & price[]) {
   return (1);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool Update() {

   if (inputTipoSpread == Dinâmico) {
      data_inicial = ObjectGetInteger(0, "spread_from_line", OBJPROP_TIME);
      barFrom = iBarShift(NULL, PERIOD_CURRENT, data_inicial) + 2;
   }

   totalRates = SeriesInfoInteger(_Symbol, PERIOD_CURRENT, SERIES_BARS_COUNT);
   if (totalRates >= barFrom)
      totalRates = barFrom;

   int lastIndex = totalRates - 1;

   if (lastIndex <= 0)
      return false;

   if (ArraySize(spreadBuffer) <= 0)
      return false;

   double price1, price2, price3;
   double fech1, fech2, fech3;
   datetime ontem, atual;

   ArrayInitialize(bufferAtivo1, 0);
   ArrayInitialize(bufferAtivo2, 0);
   ArrayInitialize(bufferAtivo3, 0);
   ArrayInitialize(bufferShowPrice1, 0);
   ArrayInitialize(bufferShowPrice2, 0);
   ArrayInitialize(bufferShowPrice3, 0);

   for(int i = 0; i <= lastIndex - 1; i++) {

      ontem = StringToTime(TimeToString(iTime(ativo1, PERIOD_CURRENT, i)  - PeriodSeconds(PERIOD_D1), TIME_DATE));
      atual = iTime(ativo1, PERIOD_CURRENT, i);
      int barOntem = iBarShift(ativo1, PERIOD_CURRENT, ontem);

      if (ativo1 != "") {
         if (referencia1 <= 0) {
            if (inputTipoSpread == Intraday) {
               if (inputSource1 == Close)
                  fech1 = iClose(ativo1, PERIOD_D1, iBarShift(ativo1, PERIOD_D1, ontem));
               else if (inputSource1 == High)
                  fech1 = iHigh(ativo1, PERIOD_D1, iBarShift(ativo1, PERIOD_D1, ontem));
               else if (inputSource1 == Low)
                  fech1 = iLow(ativo1, PERIOD_D1, iBarShift(ativo1, PERIOD_D1, ontem));
            } else {
               if (inputSource1 == Close)
                  fech1 = iClose(ativo1, PERIOD_CURRENT, barFrom);
               else if (inputSource1 == High)
                  fech1 = iHigh(ativo1, PERIOD_CURRENT, barFrom);
               else if (inputSource1 == Low)
                  fech1 = iLow(ativo1, PERIOD_CURRENT, barFrom);
            }
         } else {
            fech1 = referencia1;
         }

         //price1 = iClose(ativo1, PERIOD_CURRENT, iBarShift(ativo1, PERIOD_CURRENT, atual));
         if (inputSource1 == Close)
            price1 = iClose(ativo1, PERIOD_CURRENT, iBarShift(ativo1, PERIOD_CURRENT, atual));
         else if (inputSource1 == High)
            price1 = iHigh(ativo1, PERIOD_CURRENT, iBarShift(ativo1, PERIOD_CURRENT, atual));
         else if (inputSource1 == Low)
            price1 = iLow(ativo1, PERIOD_CURRENT, iBarShift(ativo1, PERIOD_CURRENT, atual));
      }

      if (ativo2 != "") {
         if (referencia2 <= 0) {
            if (inputTipoSpread == Intraday) {
               if (inputSource2 == Close)
                  fech2 = iClose(ativo2, PERIOD_D1, iBarShift(ativo2, PERIOD_D1, ontem));
               else if (inputSource2 == High)
                  fech2 = iHigh(ativo2, PERIOD_D1, iBarShift(ativo2, PERIOD_D1, ontem));
               else if (inputSource2 == Low)
                  fech2 = iLow(ativo2, PERIOD_D1, iBarShift(ativo2, PERIOD_D1, ontem));
            } else {
               if (inputSource2 == Close)
                  fech2 = iClose(ativo2, PERIOD_CURRENT, barFrom);
               else if (inputSource2 == High)
                  fech2 = iHigh(ativo2, PERIOD_CURRENT, barFrom);
               else if (inputSource2 == Low)
                  fech2 = iLow(ativo2, PERIOD_CURRENT, barFrom);
            }
         } else {
            fech2 = referencia2;
         }
         //price2 = iClose(ativo2, PERIOD_CURRENT, iBarShift(ativo2, PERIOD_CURRENT, atual));
         if (inputSource2 == Close)
            price2 = iClose(ativo2, PERIOD_CURRENT, iBarShift(ativo2, PERIOD_CURRENT, atual));
         else if (inputSource2 == High)
            price2 = iHigh(ativo2, PERIOD_CURRENT, iBarShift(ativo2, PERIOD_CURRENT, atual));
         else if (inputSource2 == Low)
            price2 = iLow(ativo2, PERIOD_CURRENT, iBarShift(ativo2, PERIOD_CURRENT, atual));
      }

      if (ativo3 != "") {
         if (referencia3 <= 0) {
            if (inputTipoSpread == Intraday) {
               if (inputSource3 == Close)
                  fech3 = iClose(ativo3, PERIOD_D1, iBarShift(ativo3, PERIOD_D1, ontem));
               else if (inputSource3 == High)
                  fech3 = iHigh(ativo3, PERIOD_D1, iBarShift(ativo3, PERIOD_D1, ontem));
               else if (inputSource3 == Low)
                  fech3 = iLow(ativo3, PERIOD_D1, iBarShift(ativo3, PERIOD_D1, ontem));
            } else {
               if (inputSource3 == Close)
                  fech3 = iClose(ativo3, PERIOD_CURRENT, barFrom);
               else if (inputSource3 == High)
                  fech3 = iHigh(ativo3, PERIOD_CURRENT, barFrom);
               else if (inputSource3 == Low)
                  fech3 = iLow(ativo3, PERIOD_CURRENT, barFrom);
            }
         } else {
            fech3 = referencia3;
         }

         //price3 = iClose(ativo3, PERIOD_CURRENT, iBarShift(ativo3, PERIOD_CURRENT, atual));
         if (inputSource3 == Close)
            price3 = iClose(ativo3, PERIOD_CURRENT, iBarShift(ativo3, PERIOD_CURRENT, atual));
         else if (inputSource3 == High)
            price3 = iHigh(ativo3, PERIOD_CURRENT, iBarShift(ativo3, PERIOD_CURRENT, atual));
         else if (inputSource3 == Low)
            price3 = iLow(ativo3, PERIOD_CURRENT, iBarShift(ativo3, PERIOD_CURRENT, atual));
      }
      //}

      if (ativo1 != "" && fech1 > 0) {
         if (price1 >= fech1) {
            if (showPrice) {
               bufferAtivo1[i] = (price1 / fech1 - 1) * 100;
               bufferShowPrice1[i] = fech1 * (1 + (price1 / fech1 - 1));
            } else {
               bufferAtivo1[i] = (price1 / fech1 - 1) * 100;
               bufferShowPrice1[i] = (price1 / fech1 - 1) * 100;
            }
         } else {
            if (showPrice) {
               bufferAtivo1[i] = (1 - price1 / fech1) * -100;
               bufferShowPrice1[i] = fech1 * (1 - (1 - price1 / fech1));
            } else {
               bufferAtivo1[i] = (1 - price1 / fech1) * -100;
               bufferShowPrice1[i] = (1 - price1 / fech1) * -100;
            }
         }
      } else {
         bufferAtivo1[i] = 0;
         bufferShowPrice1[i] = 0;
      }

      if (ativo2 != "" && fech2 > 0) {
         if (price2 >= fech2) {
            if (showPrice) {
               bufferAtivo2[i] = (price2 / fech2 - 1) * 100;
               bufferShowPrice2[i] = fech2 * (1 + (price2 / fech2 - 1));
            } else {
               bufferAtivo2[i] = (price2 / fech2 - 1) * 100;
               bufferShowPrice2[i] = (price2 / fech2 - 1) * 100;
            }
         } else {
            if (showPrice) {
               bufferAtivo2[i] = (1 - price2 / fech2) * -100;
               bufferShowPrice2[i] = fech2 * (1 - (1 - price2 / fech2));
            } else {
               bufferAtivo2[i] = (1 - price2 / fech2) * -100;
               bufferShowPrice2[i] = (1 - price2 / fech2) * -100;
            }
         }
      } else {
         bufferAtivo2[i] = 0;
         bufferShowPrice2[i] = 0;
      }


      if (ativo3 != "" && fech3 > 0) {
         if (price3 >= fech3) {
            if (showPrice) {
               bufferAtivo3[i] = (price3 / fech3 - 1) * 100;
               bufferShowPrice3[i] = fech3 * (1 + (price3 / fech3 - 1));
            } else {
               bufferAtivo3[i] = (price3 / fech3 - 1) * 100;
               bufferShowPrice3[i] = fech3 * (1 + (price3 / fech3 - 1));
            }
         } else {
            if (showPrice) {
               bufferAtivo3[i] = (1 - price3 / fech3) * -100;
               bufferShowPrice3[i] = fech3 * (1 - (1 - price3 / fech3));
            } else {
               bufferAtivo3[i] = (1 - price3 / fech3) * -100;
               bufferShowPrice3[i] = fech3 * (1 - (1 - price3 / fech3));
            }
         }
      } else {
         bufferAtivo3[i] = 0;
         bufferShowPrice3[i] = 0;
      }
   }

   for(int n = 0; n < ArraySize(regChannelBufferAtivo1) - 1; n++) {
      regChannelBufferAtivo1[n] = 0.0;
      regChannelBufferAtivo2[n] = 0.0;
      regChannelBufferAtivo3[n] = 0.0;

      regChannelAtivo1_1[n] = 0.0;
      regChannelAtivo1_2[n] = 0.0;
      regChannelAtivo1_3[n] = 0.0;
      regChannelAtivo1_4[n] = 0.0;
      regChannelAtivo1_5[n] = 0.0;
      regChannelAtivo1_6[n] = 0.0;
      regChannelAtivo1_7[n] = 0.0;
      regChannelAtivo1_8[n] = 0.0;
      regChannelAtivo1_9[n] = 0.0;
      regChannelAtivo1_10[n] = 0.0;
      regChannelAtivo1_11[n] = 0.0;
      regChannelAtivo1_12[n] = 0.0;

      regChannelAtivo2_1[n] = 0.0;
      regChannelAtivo2_2[n] = 0.0;
      regChannelAtivo2_3[n] = 0.0;
      regChannelAtivo2_4[n] = 0.0;
      regChannelAtivo2_5[n] = 0.0;
      regChannelAtivo2_6[n] = 0.0;
      regChannelAtivo2_7[n] = 0.0;
      regChannelAtivo2_8[n] = 0.0;
      regChannelAtivo2_9[n] = 0.0;
      regChannelAtivo2_10[n] = 0.0;
      regChannelAtivo2_11[n] = 0.0;
      regChannelAtivo2_12[n] = 0.0;

      regChannelAtivo3_1[n] = 0.0;
      regChannelAtivo3_2[n] = 0.0;
      regChannelAtivo3_3[n] = 0.0;
      regChannelAtivo3_4[n] = 0.0;
      regChannelAtivo3_5[n] = 0.0;
      regChannelAtivo3_6[n] = 0.0;
      regChannelAtivo3_7[n] = 0.0;
      regChannelAtivo3_8[n] = 0.0;
      regChannelAtivo3_9[n] = 0.0;
      regChannelAtivo3_10[n] = 0.0;
      regChannelAtivo3_11[n] = 0.0;
      regChannelAtivo3_12[n] = 0.0;
   }

   double dataArray[];

   if (ativo1 != "") {
      ArrayFree(dataArray);
      ArrayCopy(dataArray, bufferAtivo1);
      ArrayReverse(dataArray);
      if (!exibeCurva) {
         CalcAB(dataArray, 0, barFrom, A, B);
         stdev = GetStdDev(dataArray, 0, barFrom); //calculate standand deviation
      }

      for (int i = 0; i < barFrom  && !_StopFlag; i++) {
         if (exibeCurva) {
            CalcAB(dataArray, i, barFrom, A, B);
            stdev = GetStdDev(dataArray, i, barFrom);
         }

         if (showPrice) {
            regChannelBufferAtivo1[i] = fech1 * (1 + (A * (i) + B) / 100);

            regChannelAtivo1_1[i] = fech1 * (1 + ((A * (i) + B) + (6 + offset1) * desvioAtivo1 * stdev) / 100);
            regChannelAtivo1_2[i] = fech1 * (1 + ((A * (i) + B) + (5 + offset1) * desvioAtivo1 * stdev) / 100);
            regChannelAtivo1_3[i] = fech1 * (1 + ((A * (i) + B) + (4 + offset1) * desvioAtivo1 * stdev) / 100);
            regChannelAtivo1_4[i] = fech1 * (1 + ((A * (i) + B) + (3 + offset1) * desvioAtivo1 * stdev) / 100);
            regChannelAtivo1_5[i] = fech1 * (1 + ((A * (i) + B) + (2 + offset1) * desvioAtivo1 * stdev) / 100);
            regChannelAtivo1_6[i] = fech1 * (1 + ((A * (i) + B) + (1 + offset1) * desvioAtivo1 * stdev) / 100);
            regChannelAtivo1_7[i] = fech1 * (1 + ((A * (i) + B) - (1 + offset1) * desvioAtivo1 * stdev) / 100);
            regChannelAtivo1_8[i] = fech1 * (1 + ((A * (i) + B) - (2 + offset1) * desvioAtivo1 * stdev) / 100);
            regChannelAtivo1_9[i] = fech1 * (1 + ((A * (i) + B) - (3 + offset1) * desvioAtivo1 * stdev) / 100);
            regChannelAtivo1_10[i] = fech1 * (1 + ((A * (i) + B) - (4 + offset1) * desvioAtivo1 * stdev) / 100);
            regChannelAtivo1_11[i] = fech1 * (1 + ((A * (i) + B) - (5 + offset1) * desvioAtivo1 * stdev) / 100);
            regChannelAtivo1_12[i] = fech1 * (1 + ((A * (i) + B) - (6 + offset1) * desvioAtivo1 * stdev) / 100);
         } else {
            regChannelBufferAtivo1[i] = (A * (i) + B);

            regChannelAtivo1_1[i] = (A * (i) + B) + (6 + offset1) * desvioAtivo1 * stdev;
            regChannelAtivo1_2[i] = (A * (i) + B) + (5 + offset1) * desvioAtivo1 * stdev;
            regChannelAtivo1_3[i] = (A * (i) + B) + (4 + offset1) * desvioAtivo1 * stdev;
            regChannelAtivo1_4[i] = (A * (i) + B) + (3 + offset1) * desvioAtivo1 * stdev;
            regChannelAtivo1_5[i] = (A * (i) + B) + (2 + offset1) * desvioAtivo1 * stdev;
            regChannelAtivo1_6[i] = (A * (i) + B) + (1 + offset1) * desvioAtivo1 * stdev;
            regChannelAtivo1_7[i] = (A * (i) + B) - (1 + offset1) * desvioAtivo1 * stdev;
            regChannelAtivo1_8[i] = (A * (i) + B) - (2 + offset1) * desvioAtivo1 * stdev;
            regChannelAtivo1_9[i] = (A * (i) + B) - (3 + offset1) * desvioAtivo1 * stdev;
            regChannelAtivo1_10[i] = (A * (i) + B) - (4 + offset1) * desvioAtivo1 * stdev;
            regChannelAtivo1_11[i] = (A * (i) + B) - (5 + offset1) * desvioAtivo1 * stdev;
            regChannelAtivo1_12[i] = (A * (i) + B) - (6 + offset1) * desvioAtivo1 * stdev;
         }
      }
   }

   if (ativo2 != "") {
      ArrayFree(dataArray);
      ArrayCopy(dataArray, bufferAtivo2);
      ArrayReverse(dataArray);
      if (!exibeCurva) {
         CalcAB(dataArray, 0, barFrom, A, B);
         stdev = GetStdDev(dataArray, 0, barFrom); //calculate standand deviation
      }
      for (int i = 0; i < barFrom  && !_StopFlag; i++) {
         if (exibeCurva) {
            CalcAB(dataArray, i, barFrom, A, B);
            stdev = GetStdDev(dataArray, i, barFrom);
         }
         if (showPrice) {
            regChannelBufferAtivo2[i] = fech2 * (1 + (A * (i) + B) / 100);

            regChannelAtivo2_1[i] = fech2 * (1 + ((A * (i) + B) + (6 + offset2) * desvioAtivo2 * stdev) / 100);
            regChannelAtivo2_2[i] = fech2 * (1 + ((A * (i) + B) + (5 + offset2) * desvioAtivo2 * stdev) / 100);
            regChannelAtivo2_3[i] = fech2 * (1 + ((A * (i) + B) + (4 + offset2) * desvioAtivo2 * stdev) / 100);
            regChannelAtivo2_4[i] = fech2 * (1 + ((A * (i) + B) + (3 + offset2) * desvioAtivo2 * stdev) / 100);
            regChannelAtivo2_5[i] = fech2 * (1 + ((A * (i) + B) + (2 + offset2) * desvioAtivo2 * stdev) / 100);
            regChannelAtivo2_6[i] = fech2 * (1 + ((A * (i) + B) + (1 + offset2) * desvioAtivo2 * stdev) / 100);
            regChannelAtivo2_7[i] = fech2 * (1 + ((A * (i) + B) - (1 + offset2) * desvioAtivo2 * stdev) / 100);
            regChannelAtivo2_8[i] = fech2 * (1 + ((A * (i) + B) - (2 + offset2) * desvioAtivo2 * stdev) / 100);
            regChannelAtivo2_9[i] = fech2 * (1 + ((A * (i) + B) - (3 + offset2) * desvioAtivo2 * stdev) / 100);
            regChannelAtivo2_10[i] = fech2 * (1 + ((A * (i) + B) - (4 + offset2) * desvioAtivo2 * stdev) / 100);
            regChannelAtivo2_11[i] = fech2 * (1 + ((A * (i) + B) - (5 + offset2) * desvioAtivo2 * stdev) / 100);
            regChannelAtivo2_12[i] = fech2 * (1 + ((A * (i) + B) - (6 + offset2) * desvioAtivo2 * stdev) / 100);
         } else {
            regChannelBufferAtivo2[i] = (A * (i) + B);

            regChannelAtivo2_1[i] = (A * (i) + B) + (6 + offset2) * desvioAtivo2 * stdev;
            regChannelAtivo2_2[i] = (A * (i) + B) + (5 + offset2) * desvioAtivo2 * stdev;
            regChannelAtivo2_3[i] = (A * (i) + B) + (4 + offset2) * desvioAtivo2 * stdev;
            regChannelAtivo2_4[i] = (A * (i) + B) + (3 + offset2) * desvioAtivo2 * stdev;
            regChannelAtivo2_5[i] = (A * (i) + B) + (2 + offset2) * desvioAtivo2 * stdev;
            regChannelAtivo2_6[i] = (A * (i) + B) + (1 + offset2) * desvioAtivo2 * stdev;
            regChannelAtivo2_7[i] = (A * (i) + B) - (1 + offset2) * desvioAtivo2 * stdev;
            regChannelAtivo2_8[i] = (A * (i) + B) - (2 + offset2) * desvioAtivo2 * stdev;
            regChannelAtivo2_9[i] = (A * (i) + B) - (3 + offset2) * desvioAtivo2 * stdev;
            regChannelAtivo2_10[i] = (A * (i) + B) - (4 + offset2) * desvioAtivo2 * stdev;
            regChannelAtivo2_11[i] = (A * (i) + B) - (5 + offset2) * desvioAtivo2 * stdev;
            regChannelAtivo2_12[i] = (A * (i) + B) - (6 + offset2) * desvioAtivo2 * stdev;
         }

      }
   }

   if (ativo3 != "") {
      ArrayFree(dataArray);
      ArrayCopy(dataArray, bufferAtivo3);
      ArrayReverse(dataArray);
      if (!exibeCurva) {
         CalcAB(dataArray, 0, barFrom, A, B);
         stdev = GetStdDev(dataArray, 0, barFrom); //calculate standand deviation
      }
      for (int i = 0; i < barFrom  && !_StopFlag; i++) {
         if (exibeCurva) {
            CalcAB(dataArray, i, barFrom, A, B);
            stdev = GetStdDev(dataArray, i, barFrom);
         }
         if (showPrice) {
            regChannelBufferAtivo3[i] = fech3 * (1 + (A * (i) + B) / 100);

            regChannelAtivo3_1[i] = fech3 * (1 + ((A * (i) + B) + (6 + offset3) * desvioAtivo3 * stdev) / 100);
            regChannelAtivo3_2[i] = fech3 * (1 + ((A * (i) + B) + (5 + offset3) * desvioAtivo3 * stdev) / 100);
            regChannelAtivo3_3[i] = fech3 * (1 + ((A * (i) + B) + (4 + offset3) * desvioAtivo3 * stdev) / 100);
            regChannelAtivo3_4[i] = fech3 * (1 + ((A * (i) + B) + (3 + offset3) * desvioAtivo3 * stdev) / 100);
            regChannelAtivo3_5[i] = fech3 * (1 + ((A * (i) + B) + (2 + offset3) * desvioAtivo3 * stdev) / 100);
            regChannelAtivo3_6[i] = fech3 * (1 + ((A * (i) + B) + (1 + offset3) * desvioAtivo3 * stdev) / 100);
            regChannelAtivo3_7[i] = fech3 * (1 + ((A * (i) + B) - (1 + offset3) * desvioAtivo3 * stdev) / 100);
            regChannelAtivo3_8[i] = fech3 * (1 + ((A * (i) + B) - (2 + offset3) * desvioAtivo3 * stdev) / 100);
            regChannelAtivo3_9[i] = fech3 * (1 + ((A * (i) + B) - (3 + offset3) * desvioAtivo3 * stdev) / 100);
            regChannelAtivo3_10[i] = fech3 * (1 + ((A * (i) + B) - (4 + offset3) * desvioAtivo3 * stdev) / 100);
            regChannelAtivo3_11[i] = fech3 * (1 + ((A * (i) + B) - (5 + offset3) * desvioAtivo3 * stdev) / 100);
            regChannelAtivo3_12[i] = fech3 * (1 + ((A * (i) + B) - (6 + offset3) * desvioAtivo3 * stdev) / 100);
         } else {
            regChannelBufferAtivo3[i] = (A * (i) + B);

            regChannelAtivo3_1[i] = (A * (i) + B) + (6 + offset3) * desvioAtivo3 * stdev;
            regChannelAtivo3_2[i] = (A * (i) + B) + (5 + offset3) * desvioAtivo3 * stdev;
            regChannelAtivo3_3[i] = (A * (i) + B) + (4 + offset3) * desvioAtivo3 * stdev;
            regChannelAtivo3_4[i] = (A * (i) + B) + (3 + offset3) * desvioAtivo3 * stdev;
            regChannelAtivo3_5[i] = (A * (i) + B) + (2 + offset3) * desvioAtivo3 * stdev;
            regChannelAtivo3_6[i] = (A * (i) + B) + (1 + offset3) * desvioAtivo3 * stdev;
            regChannelAtivo3_7[i] = (A * (i) + B) - (1 + offset3) * desvioAtivo3 * stdev;
            regChannelAtivo3_8[i] = (A * (i) + B) - (2 + offset3) * desvioAtivo3 * stdev;
            regChannelAtivo3_9[i] = (A * (i) + B) - (3 + offset3) * desvioAtivo3 * stdev;
            regChannelAtivo3_10[i] = (A * (i) + B) - (4 + offset3) * desvioAtivo3 * stdev;
            regChannelAtivo3_11[i] = (A * (i) + B) - (5 + offset3) * desvioAtivo3 * stdev;
            regChannelAtivo3_12[i] = (A * (i) + B) - (6 + offset3) * desvioAtivo3 * stdev;
         }
      }
   }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   double max, min;
   double tempArrayMax[], tempArrayMin[];
   int firstVisibleBar = (int)ChartGetInteger(ChartID(), CHART_FIRST_VISIBLE_BAR);
   int targetBar;

   if (barFrom > firstVisibleBar)
      targetBar = firstVisibleBar;
   else
      targetBar = barFrom;

   if (showPrice) {
      double tempArray[];

      if (ativo1 != "") {
         ArrayCopy(tempArray, regChannelAtivo1_1, 0, 0, targetBar);
         ArrayAdd(tempArrayMax, tempArray[ArrayMaximum(tempArray)]);
         ArrayCopy(tempArray, regChannelAtivo1_12, 0, 0, targetBar);
         ArrayAdd(tempArrayMin, tempArray[ArrayMinimum(tempArray)]);
      }

      if (ativo2 != "") {
         ArrayCopy(tempArray, regChannelAtivo2_1, 0, 0, targetBar);
         ArrayAdd(tempArrayMax, tempArray[ArrayMaximum(tempArray)]);
         ArrayCopy(tempArray, regChannelAtivo2_12, 0, 0, targetBar);
         ArrayAdd(tempArrayMin, tempArray[ArrayMinimum(tempArray)]);
      }

      if (ativo3 != "") {
         ArrayCopy(tempArray, regChannelAtivo3_1, 0, 0, targetBar);
         ArrayAdd(tempArrayMax, tempArray[ArrayMaximum(tempArray)]);
         ArrayCopy(tempArray, regChannelAtivo3_12, 0, 0, targetBar);
         ArrayAdd(tempArrayMin, tempArray[ArrayMinimum(tempArray)]);
      }

      max = tempArrayMax[ArrayMaximum(tempArrayMax)];
      min = tempArrayMin[ArrayMinimum(tempArrayMin)];
   } else {
      if (inputTipoSpread == Intraday) {
         double tempArray[] = {spreadBuffer[0],
                               bufferAtivo1[0],
                               bufferAtivo2[0],
                               bufferAtivo3[0],
                               bufferAtivo23[0]
                              };
         max = tempArray[ArrayMaximum(tempArray)];
         min = tempArray[ArrayMinimum(tempArray)];
      } else {
         ArrayAdd(tempArrayMax, spreadBuffer[ArrayMaximum(spreadBuffer)]);
         if (ativo1 != "") ArrayAdd(tempArrayMax, bufferAtivo1[ArrayMaximum(bufferAtivo1)]);
         if (ativo2 != "") ArrayAdd(tempArrayMax, bufferAtivo2[ArrayMaximum(bufferAtivo2)]);
         if (ativo3 != "") ArrayAdd(tempArrayMax, bufferAtivo3[ArrayMaximum(bufferAtivo3)]);
         if (ativo2 != "" && ativo3 != "") ArrayAdd(tempArrayMax, bufferAtivo23[ArrayMaximum(bufferAtivo23)]);

         ArrayAdd(tempArrayMin, spreadBuffer[ArrayMinimum(spreadBuffer)]);
         if (ativo1 != "") ArrayAdd(tempArrayMin, bufferAtivo1[ArrayMinimum(bufferAtivo1)]);
         if (ativo2 != "") ArrayAdd(tempArrayMin, bufferAtivo2[ArrayMinimum(bufferAtivo2)]);
         if (ativo3 != "") ArrayAdd(tempArrayMin, bufferAtivo3[ArrayMinimum(bufferAtivo3)]);
         if (ativo2 != "" && ativo3 != "") ArrayAdd(tempArrayMin, bufferAtivo23[ArrayMinimum(bufferAtivo23)]);
         max = tempArrayMax[ArrayMaximum(tempArrayMax)];
         min = tempArrayMin[ArrayMinimum(tempArrayMin)];
      }
   }

//ChartSetInteger(0, CHART_SCALEFIX, 0, true);
//ChartSetDouble(0, CHART_FIXED_MAX, max + 1);
//ChartSetDouble(0, CHART_FIXED_MIN, min - 1);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   if (escalaMax == 0)
      IndicatorSetDouble(INDICATOR_MAXIMUM, max + 1);
   else
      IndicatorSetDouble(INDICATOR_MAXIMUM, escalaMax);

   if (escalaMin == 0)
      IndicatorSetDouble(INDICATOR_MINIMUM, min - 1);
   else
      IndicatorSetDouble(INDICATOR_MINIMUM, escalaMin);

   return(true);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   CheckTimer();
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {

   delete(_updateTimer);
   if(UninitializeReason() == REASON_REMOVE) {
      ObjectDelete(0, "spread_from_line");
      ObjectDelete(0, "spread_level");
      ObjectsDeleteAll(0, "spread_legenda");
   }
   ChartRedraw();

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckTimer() {

   EventKillTimer();

   if(_updateTimer.Check() || !_lastOK) {
      _lastOK = Update();

      EventSetMillisecondTimer(WaitMilliseconds);

      ChartRedraw();
      if (debug) Print("Spread WIN-WDO " + " " + _Symbol + ":" + GetTimeFrame(Period()) + " ok");

      _updateTimer.Reset();
   } else {
      EventSetTimer(1);
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class MillisecondTimer {

 private:
   int               _milliseconds;
 private:
   uint              _lastTick;

 public:
   void              MillisecondTimer(const int milliseconds, const bool reset = true) {
      _milliseconds = milliseconds;

      if(reset)
         Reset();
      else
         _lastTick = 0;
   }

 public:
   bool              Check() {
      uint now = getCurrentTick();
      bool stop = now >= _lastTick + _milliseconds;

      if(stop)
         _lastTick = now;

      return(stop);
   }

 public:
   void              Reset() {
      _lastTick = getCurrentTick();
   }

 private:
   uint              getCurrentTick() const {
      return(GetTickCount());
   }

};

bool _lastOK = false;
MillisecondTimer *_updateTimer;

//+---------------------------------------------------------------------+
//| GetTimeFrame function - returns the textual timeframe               |
//+---------------------------------------------------------------------+
string GetTimeFrame(int lPeriod) {
   switch(lPeriod) {
   case PERIOD_M1:
      return("M1");
   case PERIOD_M2:
      return("M2");
   case PERIOD_M3:
      return("M3");
   case PERIOD_M4:
      return("M4");
   case PERIOD_M5:
      return("M5");
   case PERIOD_M6:
      return("M6");
   case PERIOD_M10:
      return("M10");
   case PERIOD_M12:
      return("M12");
   case PERIOD_M15:
      return("M15");
   case PERIOD_M20:
      return("M20");
   case PERIOD_M30:
      return("M30");
   case PERIOD_H1:
      return("H1");
   case PERIOD_H2:
      return("H2");
   case PERIOD_H3:
      return("H3");
   case PERIOD_H4:
      return("H4");
   case PERIOD_H6:
      return("H6");
   case PERIOD_H8:
      return("H8");
   case PERIOD_H12:
      return("H12");
   case PERIOD_D1:
      return("D1");
   case PERIOD_W1:
      return("W1");
   case PERIOD_MN1:
      return("MN1");
   }
   return IntegerToString(lPeriod);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//Linear Regression Calculation for sample data: arr[]
//line equation  y = f(x)  = ax + b
void CalcAB(const double & arr[], int start, int end, double & a, double & b) {

   a = 0.0;
   b = 0.0;
   int size = MathAbs(start - end) + 1;
   if(size < 2)
      return;

   double sumxy = 0.0, sumx = 0.0, sumy = 0.0, sumx2 = 0.0;
   for(int i = start; i < end; i++) {
      sumxy += i * arr[i];
      sumy += arr[i];
      sumx += i;
      sumx2 += i * i;
   }

   double M = size * sumx2 - sumx * sumx;
   if(M == 0.0)
      return;

   a = (size * sumxy - sumx * sumy) / M;
   b = (sumy - a * sumx) / size;

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetStdDev(const double & arr[], int start, int end) {
   int size = MathAbs(start - end) + 1;
   if(size < 2)
      return(0.0);

   double sum = 0.0;
   for(int i = start; i < end; i++) {
      sum = sum + arr[i];
   }

   sum = sum / size;

   double sum2 = 0.0;
   for(int i = start; i < end; i++) {
      sum2 = sum2 + (arr[i] - sum) * (arr[i] - sum);
   }

   sum2 = sum2 / (size - 1);
   sum2 = MathSqrt(sum2);

   return(sum2);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ArrayAdd(int &sourceArr[], int value) {
   int iLast = ArraySize(sourceArr);        // End
   ArrayResize(sourceArr, iLast + 1);       // Make room
   sourceArr[iLast] = value;                // Store at new
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ArrayAdd(double & sourceArr[], double value) {
   int iLast = ArraySize(sourceArr);        // End
   ArrayResize(sourceArr, iLast + 1);       // Make room
   sourceArr[iLast] = value;                // Store at new
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void DrawVLine(const string name, const datetime time1, const color lineColor, const int width, const int style, const bool back = true, const bool hidden = true, const bool selectable = false, const int zorder = 0) {
   ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_VLINE, 0, time1, 0);
   ObjectSetInteger(0, name, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, name, OBJPROP_BACK, back);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, hidden);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, selectable);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, zorder);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string getSourceName(ENUM_REG_SOURCE src) {
   string name;
   switch(src) {
   case Open:
      name = "Open";
      break;
   case High:
      name = "High";
      break;
   case Low:
      name = "Low";
      break;
   case Close:
      name = "Close";
      break;
   case Typical:
      name = "Typical";
      break;
   default:
      name = "Close";
   }

   return name;
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
