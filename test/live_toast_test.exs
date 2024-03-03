defmodule LiveToastTest do
  use ExUnit.Case
  doctest LiveToast

  test "greets the world" do
    assert LiveToast.hello() == :world
  end
end
