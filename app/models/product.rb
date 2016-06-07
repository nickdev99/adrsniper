class Product < ActiveRecord::Base

  monetize :price_cents
  monetize :elite_price_cents

  def human_price(elite, cents: false, gr: nil)
      if non_elite_only and elite
          return nil
      end

      if elite_only and !elite
          return nil
      end

      if elite
          if cents
              ret = elite_price_cents
          else
              ret = elite_price
          end
      else
          if cents
              ret = price_cents
          else
              ret = price
          end
      end

      puts gr
      puts cents
      if gr
          puts "gr"
          g = Group.find(gr)
          if g.discount_type == 'pct'
              return ret - (ret * (g.discount_size / 100.0))
          else
              return ret - g.discount_size
          end
      else
          puts "nogr"
          return ret
      end
  end
end
