Code.require_file "../test_helper.exs", __FILE__

defmodule CruddyTest do
  use ExUnit.Case

  import Cruddy

  defmodule Events do
    import Evented

    defevent :incr
    defevent :decr
    defevent :sq
    defevent :algo
  end

  defmodule Calculator do
    import Events

    incr :add_1
    decr :sub_1
    sq :exp_2
    algo [:add_1, :exp_2, :sub_1]

    defp add_1(n) do
      IO.puts "adding #{inspect n}"
      n + 1
    end

    defp sub_1(n) do
      IO.puts "subtracting #{inspect n}"
      n - 1
    end

    defp exp_2(n) do        
      IO.puts "exponentiating #{inspect n}"
      n * n
    end
  end

  defcrudable Post do
    fields [:id, :title, :body, :state]

    on_create :do_create
    on_read :do_read
    on_update :do_update
    on_delete :do_delete
    on_exists? :do_exists

    alias __MODULE__, as: Rec

    defp do_exists(Rec[state: :new] = rec), do: false
    defp do_exists(Rec[state: :created] = rec), do: true

    defp do_create(rec) do
      rec.state :created
    end

    defp do_read(id) do
      __MODULE__.new id: id, state: :new
    end
    
    defp do_update(rec), do: rec
    
    defp do_delete(rec), do: true
  end

  test :evented do
    assert Calculator.trigger(:incr, 1) == 2
    assert Calculator.trigger(:decr, 4) == 3
    assert Calculator.trigger(:sq,   2) == 4
    assert Calculator.trigger(:algo, 3) == 15
  end

  test :read do
    post = Post.find(123)
    assert post.id == 123
  end

  test :exists? do
    post = Post.find(123)
    assert not post.exists?
  end
end
