class Checkout
  def complete_checkout
    TotalsCalculator.new(self).calculate

    if pay
      post_completed_actions
    else
      redirect_to_payment_error_page
    end
  end

  def post_completed_actions
    self.state = "completed"
    send_completed_email
    MONITOR.increment(:checkout_completed)
  end

  def send_completed_email
    email = Email.new(:checkout_completed, checkout: self)
    email.send
  end

  def pay
    authorize_money_from_bank(self.card_amount) && debit_funds_from_user(self.user_funds_amount)
  end
end

class TotalsCalculator

  def initialize(checkout)
    @checkout = checkout
  end

  def calculate
    @checkout.total = @checkout.orders.map{|o| o.products.map(&:price).reduce(&:+)}.reduce(&:+)
    calculate_amounts_to_pay
  end

  def calculate_amounts_to_pay
    @checkout.card_amount = @checkout.total
    @checkout.user_funds_amount = 0
    if @checkout.user.has_customer_funds?
      @checkout.card_amount = @checkout.total - user.customer_funds
      @checkout.user_funds_amount = user.customer_funds
    end
  end
end
