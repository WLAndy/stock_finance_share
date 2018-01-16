class Admin::BaseDataController < AdminController

  def index
    #code
  end

  # 全局扫描更新 沪股 股票代码和名称
  def update_stock_symbol

    response = RestClient.get "http://web.juhe.cn:8080/finance/stock/shall", :params => { :key => KEY_CONFIG["juhe_api_key"], :page => "1", :type => "1" }
    data = JSON.parse(response.body)

    data["result"]["data"].each do |s|
      existing_stock = Stock.find_by_symbol( s["symbol"] )
      if existing_stock.nil?
        Stock.create!(
          :symbol => s["symbol"],
          :name => s["name"]
        )
      end
    end
    puts "更新完毕*******"
    flash[:notice] = "沪股 股票代码和名称 更新完毕"

  end

  #全局扫描更新 三表数据 股票行业
  def update_stock_finance_table
    @stocks = Stock.all
    @stocks.each do |s|

      # zcb 资产表更新
      response_zcb = RestClient.get "http://future.liangyee.com/bus-api/corporateFinance/MainStockFinance/getBalanceSheet", :params => { :userKey => KEY_CONFIG["liangyee_api_key"], :symbol => s.symbol[2..7], :yearly => false }
      data_zcb = JSON.parse(response_zcb.body)
      s.update!(
        :zcb => data_zcb["result"],
      )

      # lrb 利润表更新
      response_lrb = RestClient.get "http://future.liangyee.com/bus-api/corporateFinance/MainStockFinance/getStockProfit", :params => { :userKey => KEY_CONFIG["liangyee_api_key"], :symbol => s.symbol[2..7], :yearly => false }
      data_lrb = JSON.parse(response_lrb.body)
      s.update!(
        :lrb => data_lrb["result"],
      )

      # llb 流量表更新
      response_llb = RestClient.get "http://future.liangyee.com/bus-api/corporateFinance/MainStockFinance/getStockCashFlow", :params => { :userKey => KEY_CONFIG["liangyee_api_key"], :symbol => s.symbol[2..7], :yearly => false }
      data_llb = JSON.parse(response_llb.body)
      s.update!(
        :llb => data_llb["result"],
      )

      # fzb 负债表更新
      response_fzb = RestClient.get "http://future.liangyee.com/bus-api/corporateFinance/MainStockFinance/GetBalanceSheetLiabilities", :params => { :userKey => KEY_CONFIG["liangyee_api_key"], :symbol => s.symbol[2..7], :yearly => false }
      data_fzb = JSON.parse(response_fzb.body)
      s.update!(
        :fzb => data_fzb["result"],
      )

      # gdb 股东权益表更新
      response_gdb = RestClient.get "http://future.liangyee.com/bus-api/corporateFinance/MainStockFinance/GetBalanceSheetShareholder", :params => { :userKey => KEY_CONFIG["liangyee_api_key"], :symbol => s.symbol[2..7], :yearly => false }
      data_gdb = JSON.parse(response_gdb.body)
      s.update!(
        :gdb => data_gdb["result"],
      )

      # industry 行业分类更新
      existing_stock_industry = s.industry
      if existing_stock_industry.nil?
        response_industry = RestClient.get "http://future.liangyee.com/bus-api/corporateFinance/MainStockFinance/GetStockIndustryClassification", :params => { :userKey => KEY_CONFIG["liangyee_api_key"], :symbol => s.symbol[2..7] }
        data_industry = JSON.parse(response_industry.body)
        s.update!(
          :industry => data_industry["result"],
        )
      end

    end

    flash[:notice] = "三表数据 股票行业 更新完毕"
  end


end