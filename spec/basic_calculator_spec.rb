require './basic_calculator.rb'

describe "calculator" do
  context "with valid inputs" do
    where(:input, :result) do
      [
        ['1989', 1989],
        ['(1989)', 1989],
        ['1+2', 3],
        ['4/2', 2],
        ['4/(1+1)', 2],
        ['4/1+1', 5],
        ['1+2*3', 7],
        ['(1+2)*3', 9],
        ['(1+2)*3-1*2', 7],
        ['( ( 2 + 3 ) * 5 ) )', 25],
        ['((( 2 + 3) *5)- 13 )', 12],
      ]
    end

    with_them do
      it "calculates the correct value" do
        expect(Calculator.calculate(input)).to eq(result)
      end
    end
  end
end
