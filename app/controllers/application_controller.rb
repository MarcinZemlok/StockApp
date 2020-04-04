require 'dotenv/load'
require 'httparty'

$finnhubToken = ENV['FINNHUB_KEY']
$quandlToken = ENV['QUANDL_KEY']

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def fetchQuandleNew(_index)
    # return if not stockOpen

    _newestRow = (Gpw.where(:index=>_index).order(date: :desc).take(1))[0].date

    _qData = fetchData(_index, _newestRow)

    saveData(_index, _qData)

    return

    # @filteredIndexes.each do |symbol|
    #     @qData[symbol] = {}
    #     @qData[symbol][:calcs] = {}

    #     if(fetchRequired(symbol))
    #         @qData[symbol][:meta] = fetchMeta(symbol)['dataset']
    #         calculateLastUpdatedSpan(symbol, @qData[symbol][:meta]['refreshed_at'])
    #         assesTimespan(symbol)
    #         @qData[symbol][:data] = fetchData(symbol)['dataset_data']
    #         saveData(symbol, @qData[symbol][:data]['data'])
    #     end
    # end
  end

  def fetchQuandleOld(_index)
    # return if not stockOpen

    _oldestRow = (Gpw.where(:index=>_index).order(date: :asc).take(1))[0].date

    _qData = fetchData(_index, false, _oldestRow, 100)

    saveData(_index, _qData)

    return
  end

  def fetchData(_index, _start=false, _end=false, _limit=false)
      _url = "https://www.quandl.com/api/v3/datasets/WSE/#{_index}/data.json?api_key=#{$quandlToken}"
      _url += "&start_date=#{_start}" if _start
      _url += "&end_date=#{_end}" if _end
      _url += "&limit=#{_limit}" if _limit

      mylog("URL: #{_url}")

      _res = HTTParty.get(_url)

      return JSON.parse(_res.body)['dataset_data']
  end

  def saveData(_index, _data)
      standarizeColumns(_index, _data)
      _columns = _data['column_names']

      mylog(_data)

      _data['data'].each do |_d|
          _time = Time.new(_d[0][0..3], _d[0][5..6], _d[0][8..9])
          _record = Gpw.exists?({
              index: _index,
              date: _time
          })

          _date = _d[_columns.index('date')] if _columns.index('date')
          _open = _d[_columns.index('open')] if _columns.index('open')
          _high = _d[_columns.index('high')] if _columns.index('high')
          _low = _d[_columns.index('low')] if _columns.index('low')
          _close = _d[_columns.index('close')] if _columns.index('close')
          _change = _d[_columns.index('change')] if _columns.index('change')
          _volume = _d[_columns.index('volume')] if _columns.index('volume')
          _trades = _d[_columns.index('trades')] if _columns.index('trades')
          _tornover = _d[_columns.index('turnover')] if _columns.index('turnover')

          _tmp = Gpw.new({
              :index => _index,
              :date => _date,
              :open => _open,
              :high => _high,
              :low => _low,
              :close => _close,
              :change => _change,
              :volume => _volume,
              :trades => _trades,
              :tornover => _tornover,
          }) if not _record

          _tmp.save if not _record
      end
  end

  def stockOpen
      _TODAY = Time.new

      _saturday = _TODAY.strftime('%u') == '6'
      _sunday = _TODAY.strftime('%u') == '7'

      mylog("[WARNING] Stock is closed (#{_TODAY.strftime('%A')})") if _saturday or _sunday

      return (not _saturday and not _sunday)
  end

  def standarizeColumns(_index, _data)
      _columns = _data['column_names']
      _i = 0
      _columns.each do |c|
          _columns[_i] = 'open' if 'Open'.in? c
          _columns[_i] = 'close' if 'Close'.in? c
          _columns[_i] = 'high' if 'High'.in? c
          _columns[_i] = 'low' if 'Low'.in? c
          _columns[_i] = 'date' if 'Date'.in? c
          _columns[_i] = 'change' if 'Change'.in? c
          _columns[_i] = 'volume' if 'Volume'.in? c
          _columns[_i] = 'trades' if 'Trades'.in? c
          _columns[_i] = 'turnover' if 'Turnover'.in? c

          _i+=1
      end

  end

  def mylog(_str)
      puts "\e[38:5:0m\e[48:5:15m#{_str}\e[m"
  end

  # def fetchMeta(_index)
  #     url = "https://www.quandl.com/api/v3/datasets/WSE/#{_index}/metadata.json?api_key=#{$quandlToken}"

  #     res = HTTParty.get(url)

  #     return JSON.parse(res.body)
  # end
end

class Tips < ApplicationController
    """Detects and stores all tips on a plot."""
    def initialize(_data)
        @step = computeBrickStep(_data.reverse)

        @bricks = computeBrick(_data.reverse)

        @tips = []
        detectTips
    end

    def computeBrickStep(_data)
        _sum = 0
        for _row in _data
            _sum += _row.change.abs
        end

        return (_sum / _data.length)
    end

    def computeBrick(_data)
        _result = {
            :x => [],
            :y => [],
            :value => [],
            :date => []
        }

        _index = 0
        _lastClose = _data[0].close
        _data.slice(1,_data.length).each do |_row|

            while((_row.close - _lastClose).abs >= @step)
                if (_row.close - _lastClose) < 0
                    _result[:y] += [-@step]
                    _lastClose -= @step
                else
                    _result[:y] += [@step]
                    _lastClose += @step
                end
                _result[:x] += [_index]
                _result[:date] += [_row.date]
                _result[:value] += [_lastClose]
                _index += 1
            end
        end

        return _result
    end

    def detectTips
        [*3...@bricks[:y].length].each do |_i|
            if(
                @bricks[:y][_i-3] == @bricks[:y][_i-2] &&
                @bricks[:y][_i-1] == @bricks[:y][_i] &&
                @bricks[:y][_i-3] != @bricks[:y][_i]
            )
                @tips += [Tip.new(
                    @bricks[:date][_i-3],
                    @bricks[:date][_i-1],
                    _i-3,
                    _i,
                    (@bricks[:value][_i-2] + @bricks[:value][_i-1]) / 2
                )]
            end
        end
    end
end

class Tip
    """Stores one tip on a plot and all related data."""
    def initialize(_dateStart, _dateEnd, _indexStart, _indexEnd, _value)

        @dateStart = _dateStart
        @dateEnd = _dateEnd
        @indexStart = _indexStart
        @indexEnd = _indexEnd
        @value = _value
        # @type = typeTip

    end

    # def typeTip
    #     if @
    # end
end

# All Polish stox inex codes
$allIndexes = [
    "06MAGNA",
    "08OCTAVA",
    "11BIT",
    "4FUNMEDIA",
    "ABPL",
    "ACAUTOGAZ",
    "ACTION",
    "ADIUVO",
    "AGORA",
    "AGROTON",
    "AILLERON",
    "AIRWAY",
    "ALIOR",
    "ALTA",
    "ALTUSTFI",
    "ALUMETAL",
    "AMBRA",
    "AMICA",
    "AMPLI",
    "AMREST",
    "APATOR",
    "APLISENS",
    "APSENERGY",
    "ARCHICOM",
    "ARCTIC",
    "ARCUS",
    "ARTERIA",
    "ARTIFEX",
    "ASBIS",
    "ASMGROUP",
    "ASSECOBS",
    "ASSECOPOL",
    "ASSECOSEE",
    "ASTARTA",
    "ATAL",
    "ATENDE",
    "ATLANTAPL",
    "ATLANTIS",
    "ATLASEST",
    "ATM",
    "ATMGRUPA",
    "ATREM",
    "AUGA",
    "AUTOPARTN",
    "AWBUD",
    "BAHOLDING",
    "BALTONA",
    "BBIDEV",
    "BEDZIN",
    "BENEFIT",
    "BERLING",
    "BEST",
    "BETACOM",
    "BIK",
    "BIOMEDLUB",
    "BIOTON",
    "BNPPPL",
    "BOGDANKA",
    "BOOMBIT",
    "BORYSZEW",
    "BOS",
    "BOWIM",
    "BRASTER",
    "BSCDRUK",
    "BUDIMEX",
    "BUMECH",
    "CAPITAL",
    "CCC",
    "CCENERGY",
    "CDPROJEKT",
    "CDRL",
    "CEEPLUS",
    "CELTIC",
    "CEZ",
    "CFI",
    "CHEMOS",
    "CIECH",
    "CIGAMES",
    "CITYSERV",
    "CLNPHARMA",
    "CNT",
    "COALENERG",
    "COGNOR",
    "COMARCH",
    "COMP",
    "COMPERIA",
    "CORMAY",
    "CPGROUP",
    "CUBEITG",
    "CYFRPLSAT",
    "CZTOREBKA",
    "DATAWALK",
    "DEBICA",
    "DECORA",
    "DEKPOL",
    "DELKO",
    "DEVELIA",
    "DGA",
    "DIGITREE",
    "DINOPL",
    "DOMDEV",
    "DREWEX",
    "DROP",
    "DROZAPOL",
    "ECHO",
    "EDINVEST",
    "EFEKT",
    "EKOEXPORT",
    "ELBUDOWA",
    "ELEKTROTI",
    "ELEMENTAL",
    "ELKOP",
    "ELZAB",
    "EMCINSMED",
    "ENAP",
    "ENEA",
    "ENELMED",
    "ENERGA",
    "ENERGOINS",
    "ENTER",
    "ERBUD",
    "ERG",
    "ERGIS",
    "ESOTIQ",
    "ESSYSTEM",
    "ESTAR",
    "EUCO",
    "EUROCASH",
    "EUROHOLD",
    "EUROTEL",
    "EVEREST",
    "FAMUR",
    "FASING",
    "FASTFIN",
    "FEERUM",
    "FENGHUA",
    "FERRO",
    "FERRUM",
    "FMG",
    "FON",
    "FORTE",
    "GETBACK",
    "GETIN",
    "GETINOBLE",
    "GLCOSMED",
    "GOBARTO",
    "GPW",
    "GROCLIN",
    "GRODNO",
    "GRUPAAZOTY",
    "GTC",
    "HANDLOWY",
    "HARPER",
    "HELIO",
    "HERKULES",
    "HMINWEST",
    "HOLLYWOOD",
    "HUBSTYLE",
    "HYDROTOR",
    "I2DEV",
    "IALBGR",
    "IBSM",
    "IDEABANK",
    "IDMSA",
    "IFCAPITAL",
    "IFIRMA",
    "IFSA",
    "IIAAV",
    "IMCOMPANY",
    "IMMOBILE",
    "IMPEL",
    "IMPERA",
    "IMS",
    "INC",
    "INDYGO",
    "INDYKPOL",
    "INGBSK",
    "INPRO",
    "INSTALKRK",
    "INTERAOLT",
    "INTERBUD",
    "INTERCARS",
    "INTERFERI",
    "INTERSPPL",
    "INTROL",
    "INVESTORMS",
    "INVISTA",
    "IPOPEMA",
    "IQP",
    "ITMTRADE",
    "IZOBLOK",
    "IZOLACJA",
    "IZOSTAL",
    "JHMDEV",
    "JJAUTO",
    "JSW",
    "JWCONSTR",
    "JWWINVEST",
    "K2INTERNT",
    "KANIA",
    "KBDOM",
    "KCI",
    "KDMSHIPNG",
    "KERNEL",
    "KETY",
    "KGHM",
    "KGL",
    "KINOPOL",
    "KOGENERA",
    "KOMPAP",
    "KOMPUTRON",
    "KONSSTALI",
    "KPPD",
    "KRAKCHEM",
    "KREC",
    "KREDYTIN",
    "KREZUS",
    "KRKA",
    "KRUK",
    "KRUSZWICA",
    "KRVITAMIN",
    "KSGAGRO",
    "LABOPRINT",
    "LARK",
    "LARQ",
    "LENA",
    "LENTEX",
    "LIBET",
    "LIVECHAT",
    "LOKUM",
    "LOTOS",
    "LPP",
    "LSISOFT",
    "LUBAWA",
    "MABION",
    "MAKARONPL",
    "MANGATA",
    "MARVIPOL",
    "MASTERPHA",
    "MAXCOM",
    "MBANK",
    "MBWS",
    "MCI",
    "MDIENERGIA",
    "MEDIACAP",
    "MEDIATEL",
    "MEDICALG",
    "MEGARON",
    "MENNICA",
    "MERCATOR",
    "MERCOR",
    "MEXPOLSKA",
    "MFO",
    "MILKILAND",
    "MILLENNIUM",
    "MIRACULUM",
    "MIRBUD",
    "MLPGROUP",
    "MLSYSTEM",
    "MOBRUK",
    "MOJ",
    "MOL",
    "MONNARI",
    "MORIZON",
    "MOSTALPLC",
    "MOSTALWAR",
    "MOSTALZAB",
    "MUZA",
    "MWIG40",
    "MWIG40DVP",
    "MWIG40TR",
    "MWTRADE",
    "NANOGROUP",
    "NCINDEX",
    "NETIA",
    "NEUCA",
    "NEWAG",
    "NORTCOAST",
    "NOVATURAS",
    "NOVITA",
    "NOWAGALA",
    "NTTSYSTEM",
    "OAT",
    "ODLEWNIE",
    "OEX",
    "OPENFIN",
    "OPONEO_PL",
    "OPTEAM",
    "ORANGEPL",
    "ORBIS",
    "ORCOGROUP",
    "ORION",
    "ORZBIALY",
    "OTLOG",
    "OTMUCHOW",
    "OVOSTAR",
    "PAMAPOL",
    "PANOVA",
    "PATENTUS",
    "PBG",
    "PBKM",
    "PBSFINANSE",
    "PCCEXOL",
    "PCCROKITA",
    "PCGUARD",
    "PEIXIN",
    "PEKABEX",
    "PEKAO",
    "PEMANAGER",
    "PEP",
    "PEPEES",
    "PGE",
    "PGNIG",
    "PGO",
    "PGSSOFT",
    "PHARMENA",
    "PHN",
    "PKNORLEN",
    "PKOBP",
    "PKPCARGO",
    "PLASTBOX",
    "PLATYNINW",
    "PLAY",
    "PLAYWAY",
    "PLAZACNTR",
    "PMPG",
    "POLICE",
    "POLIMEXMS",
    "POLNORD",
    "POLWAX",
    "POZBUD",
    "PRAGMAFA",
    "PRAGMAINK",
    "PRAIRIE",
    "PRIMAMODA",
    "PRIMETECH",
    "PROCAD",
    "PROCHEM",
    "PROJPRZEM",
    "PROTEKTOR",
    "PROVIDENT",
    "PULAWY",
    "PZU",
    "QUANTUM",
    "QUERCUS",
    "R22",
    "RADPOL",
    "RAFAKO",
    "RAFAMET",
    "RAINBOW",
    "RANKPROGR",
    "RAWLPLUG",
    "REDAN",
    "REGNON",
    "REINHOLD",
    "REINO",
    "RELPOL",
    "REMAK",
    "RESBUD",
    "RONSON",
    "ROPCZYCE",
    "RUBICON",
    "RYVU",
    "SADOVAYA",
    "SANOK",
    "SANPL",
    "SANTANDER",
    "SANWIL",
    "SCOPAK",
    "SECOGROUP",
    "SEKO",
    "SELENAFM",
    "SELVITA",
    "SERINUS",
    "SESCOM",
    "SETANTA",
    "SFINKS",
    "SILVAIR_REGS",
    "SILVANO",
    "SIMPLE",
    "SKARBIEC",
    "SKOTAN",
    "SKYLINE",
    "SLEEPZAG",
    "SNIEZKA",
    "SOHODEV",
    "SOLAR",
    "SONEL",
    "SOPHARMA",
    "STALEXP",
    "STALPROD",
    "STALPROFI",
    "STAPORKOW",
    "STARHEDGE",
    "STELMET",
    "SUNEX",
    "SUWARY",
    "SWIG80",
    "SWIG80DVP",
    "SWIG80TR",
    "SWISSMED",
    "SYGNITY",
    "SYNEKTIK",
    "TALANX",
    "TALEX",
    "TARCZYNSKI",
    "TATRY",
    "TAURONPE",
    "TBSP_INDEX",
    "TBULL",
    "TERMOREX",
    "TESGAS",
    "TIM",
    "TORPOL",
    "TOWERINVT",
    "TOYA",
    "TRAKCJA",
    "TRANSPOL",
    "TRITON",
    "TSGAMES",
    "TXM",
    "ULMA",
    "ULTGAMES",
    "UNIBEP",
    "UNICREDIT",
    "UNIMA",
    "UNIMOT",
    "URSUS",
    "VANTAGE",
    "VENTUREIN",
    "VIGOSYS",
    "VINDEXUS",
    "VISTAL",
    "VIVID",
    "VOTUM",
    "VOXEL",
    "VRG",
    "WADEX",
    "WARIMPEX",
    "WASKO",
    "WAWEL",
    "WIELTON",
    "WIG",
    "WIG20",
    "WIG20DVP",
    "WIG20LEV",
    "WIG20SHORT",
    "WIG20TR",
    "WIG30",
    "WIG30TR",
    "WIG_BANKI",
    "WIG_BUDOW",
    "WIG_CEE",
    "WIG_CHEMIA",
    "WIGDIV",
    "WIG_ENERG",
    "WIG_ESG",
    "WIG_GAMES",
    "WIG_GORNIC",
    "WIG_INFO",
    "WIG_LEKI",
    "WIG_MEDIA",
    "WIG_MOTO",
    "WIG_MS_BAS",
    "WIG_MS_FIN",
    "WIG_MS_PET",
    "WIG_NRCHOM",
    "WIG_ODZIEZ",
    "WIG_PALIWA",
    "WIG_POLAND",
    "WIG_SPOZYW",
    "WIGTECH",
    "WIG_TELKOM",
    "WIG_UKRAIN",
    "WIKANA",
    "WINVEST",
    "WIRTUALNA",
    "WITTCHEN",
    "WOJAS",
    "WORKSERV",
    "XTB",
    "XTPL",
    "YOLO",
    "ZAMET",
    "ZASTAL",
    "ZEPAK",
    "ZPUE",
    "ZREMB",
    "ZUE",
    "ZYWIEC"
]
