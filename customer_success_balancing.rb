require 'minitest/autorun'
require 'timeout'

class CustomerSuccessBalancing
  def initialize(customer_success, customers, away_customer_success)
    @customer_success = customer_success
    @customers = customers
    @away_customer_success = away_customer_success
  end

  def execute
    active_customers_successes = remove_offline_customer_success(@customer_success, @away_customer_success)

    lowest_customer_score = get_lowest_customer_score(@customers)
    highest_customer_score = get_highest_customer_score(@customers)

    available_customers_successes = filter_successes_by_score_range(active_customers_successes, lowest_customer_score, highest_customer_score)
    customers_sort_by_score = organize_customer_by_score(@customers)

    customers_success_with_amount_customers = calculate_customers_count_per_customers_success(customers_sort_by_score, available_customers_successes)
    customer_success_with_more_amount_customers =  get_customer_success_with_more_customers(customers_success_with_amount_customers)

    return setting_up_return(customer_success_with_more_amount_customers)
  end

  def remove_offline_customer_success(customer_success, away_customer_success)
    available_customers_successes = customer_success.select { |customer_success| !away_customer_success.include?(customer_success[:id]) }

    available_customers_successes.sort_by { |customer_success| customer_success[:score]}
  end

  def get_lowest_customer_score(customers)
    scores = customers.map { |customer| customer[:score] }
    scores.min
  end

  def get_highest_customer_score(customers)
    scores = customers.map { |customer| customer[:score] }
    scores.max
  end

  def filter_successes_by_score_range(active_customers_successes, lowest_score, highest_score)
    filtered_successes = []

    active_customers_successes.each do |customer_success|
      score = customer_success[:score]

      filtered_successes << customer_success if lowest_score <= score

      break unless highest_score > score
    end

    filtered_successes
  end

  def organize_customer_by_score(customers)
    customers.sort_by { |customer| customer[:score]}
  end

  def calculate_customers_count_per_customers_success(customers, available_customers_successes)
    customers_count_per_customers_success = []

    available_customers_successes.each do |customer_success|

      amount_customers = customers.select { |customer| customer[:score] <= customer_success[:score] }
      customers -= amount_customers

      customers_count_per_customers_success << { id: customer_success[:id], amount_customers: amount_customers.length }
    end

    customers_count_per_customers_success
  end

  def get_customer_success_with_more_customers(customers_successes)
    max_amount_customers = customers_successes.max_by { |customer_success| customer_success[:amount_customers] }
    customer_success_with_more_amount_customers = customers_successes.select { |customer_success| customer_success[:amount_customers] == max_amount_customers[:amount_customers] }
  end

  def setting_up_return(customer_success_with_more_amount_customers)
    if customer_success_with_more_amount_customers.length == 1
      return customer_success_with_more_amount_customers[0][:id]
    else
      return 0
    end
  end
end

class CustomerSuccessBalancingTests < Minitest::Test
  def test_scenario_one
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 20, 95, 75]),
      build_scores([90, 20, 70, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    balancer = CustomerSuccessBalancing.new(
      build_scores([11, 21, 31, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    balancer = CustomerSuccessBalancing.new(
      build_scores(Array(1..999)),
      build_scores(Array.new(10000, 998)),
      [999]
    )
    result = Timeout.timeout(1.0) { balancer.execute }
    assert_equal 998, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(
      build_scores([1, 2, 3, 4, 5, 6]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 2, 3, 6, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [1, 3, 2]
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [4, 5, 6]
    )
    assert_equal 3, balancer.execute
  end

  def test_scenario_eight
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 40, 95, 75]),
      build_scores([90, 70, 20, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  private

  def build_scores(scores)
    scores.map.with_index do |score, index|
      { id: index + 1, score: score }
    end
  end
end
