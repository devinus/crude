defmodule Evented do
  defmacro defevent(name) when is_atom(name) do
    __defevent__(name)
  end

  defmacro defevent(names) when is_list(names) do
    lc name inlist names, do: __defevent__(name)
  end

  def __deftrigger__(event, callback) do
    quote do
      def trigger(unquote(event), context) do
        unquote(__trigger__(callback))
      end
    end
  end

  defp __trigger__(callback) when is_atom(callback) do
    quote do: unquote(callback).(context)
  end

  defp __trigger__(callbacks) when is_list(callbacks) do
    List.foldl callbacks, [], fn cb, acc -> quote do: unquote(cb).(unquote(acc)) end
  end

  defp __defevent__(event) do
    quote do
      defmacro unquote(event)(callback) do
        unquote(__MODULE__).__deftrigger__(unquote(event), callback)
      end
    end
  end
end

defmodule Cruddy do
  import Evented

  defevent :on_create
  defevent :on_read
  defevent :on_update
  defevent :on_delete

  defmacro fields(names) do
    Module.put_attribute __CALLER__.module, :fields, names
  end

  defmacro defcrudable(name, block) do
    quote do
      defmodule unquote(name) do
        import Cruddy
        unquote(block)
        Record.deffunctions @fields ++ [__state: :new], __ENV__

        alias __MODULE__, as: Rec

        def find(id) do
          Rec.trigger(:on_read, id)
        end

        def save(Rec[__state: :new] = rec) do
          rec.trigger(:on_create)
        end

        def save(Rec[__state: :dirty] = rec) do
          rec.trigger(:on_update)
        end

        def delete(id) do
          Rec.trigger(:on_delete, id)
        end
      end
    end
  end
end

defmodule Test do
  import Cruddy

  defmodule MyEvents do
    import Evented

    defevent :some_event
  end

  defmodule Thing do
    import MyEvents

    some_event :foo

    defp foo(_rec) do
      IO.puts "foo called"
    end
  end

  defcrudable Post do
    fields [:id, :title, :body]

    on_create [:do_create, :tweet_about_it, :now_do_something_crazy]
    on_read :do_read
    # on_update :do_update
    # on_delete :do_delete

    defp do_read(id) do
      __MODULE__.new id: id
    end

    defp do_create(rec) do
      IO.puts "Created! Got: #{inspect rec}"
      :created
    end

    defp tweet_about_it(rec) do
      IO.puts "Tweeted! Got: #{inspect rec}"
      :tweeted
    end

    defp now_do_something_crazy(rec) do
      IO.puts "Something crazy! Got: #{inspect rec}"
      :something_crazy
    end

    # defp do_read(rec) do
    # end
    #
    # defp do_update(rec) do
    # end
    #
    # defp do_delete(rec) do
    # end
  end

  post = Post.find(42)
  post = post.title "Kurt stinks"
  post.save
  IO.inspect post.to_keywords
end
