require 'spec_helper'

describe GraphQL::Relay::ArrayConnection do
  def get_names(result)
    ships = result["data"]["rebels"]["ships"]["edges"]
    names = ships.map { |e| e["node"]["name"] }
  end
  describe "results" do
    let(:query_string) {%|
      query getShips($first: Int, $after: String, $last: Int, $before: String, $order: String){
        rebels {
          ships(first: $first, after: $after, last: $last, before: $before, order: $order) {
            edges {
              cursor
              node {
                name
              }
            }
            pageInfo {
              hasNextPage
            }
          }
        }
      }
    |}
    it 'limits the result' do
      result = query(query_string, "first" => 2)
      number_of_ships = get_names(result).length
      assert_equal(2, number_of_ships)
      assert_equal(true, result["data"]["rebels"]["ships"]["pageInfo"]["hasNextPage"])

      result = query(query_string, "first" => 3)
      number_of_ships = get_names(result).length
      assert_equal(3, number_of_ships)
    end

    it 'provides pageInfo' do
      result = query(query_string, "first" => 2)
      assert_equal(true, result["data"]["rebels"]["ships"]["pageInfo"]["hasNextPage"])

      result = query(query_string, "first" => 100)
      assert_equal(false, result["data"]["rebels"]["ships"]["pageInfo"]["hasNextPage"])
    end

    it 'slices the result' do
      result = query(query_string, "first" => 3)
      assert_equal(["X-Wing", "Y-Wing", "A-Wing"], get_names(result))

      # After the last result, find the next 2:
      last_cursor = result["data"]["rebels"]["ships"]["edges"].last["cursor"]

      result = query(query_string, "after" => last_cursor, "first" => 2)
      assert_equal(["Millenium Falcon", "Home One"], get_names(result))

      result = query(query_string, "before" => last_cursor, "last" => 2)
      assert_equal(["X-Wing", "Y-Wing"], get_names(result))
    end

    it 'paginates with order' do
      result = query(query_string, "first" => 2, "order" => "name")
      assert_equal(["A-Wing", "Home One"], get_names(result))

      # After the last result, find the next 2:
      last_cursor = result["data"]["rebels"]["ships"]["edges"].last["cursor"]

      result = query(query_string, "after" => last_cursor, "first" => 2, "order" => "name")
      assert_equal(["Millenium Falcon", "X-Wing"], get_names(result))
    end

    it 'paginates with reverse order' do
      result = query(query_string, "first" => 2, "order" => "-name")
      assert_equal(["Y-Wing", "X-Wing"], get_names(result))
    end
  end
end
