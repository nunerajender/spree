module Spree
  class Price < Spree::Base
    include VatPriceCalculation

    acts_as_paranoid
    belongs_to :variant, class_name: 'Spree::Variant', inverse_of: :prices, touch: true

    validate :check_price
    validates :amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validate :validate_amount_maximum

    extend DisplayMoney
    money_methods :amount, :price

    def money
      Spree::Money.new(amount || 0, { currency: currency })
    end

    def price
      amount
    end

    def price=(price)
      self[:amount] = Spree::LocalizedNumber.parse(price)
    end

    def price_including_vat_for(zone)
      gross_amount(price, zone, variant.tax_category)
    end

    def display_price_including_vat_for(zone)
      Spree::Money.new(price_including_vat_for(zone), currency: currency)
    end

    # Remove variant default_scope `deleted_at: nil`
    def variant
      Spree::Variant.unscoped { super }
    end

    private

    def check_price
      self.currency ||= Spree::Config[:currency]
    end

    def maximum_amount
      BigDecimal '999999.99'
    end

    def validate_amount_maximum
      if amount && amount > maximum_amount
        errors.add :amount, I18n.t('errors.messages.less_than_or_equal_to', count: maximum_amount)
      end
    end
  end
end
