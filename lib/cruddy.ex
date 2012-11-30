defmodule Evented do
  defmacro defevent(name) when is_atom(name) do
    __defevent__(name)
  end

  defmacro defevent(names) when is_list(names) do
    lc n inlist names, do: __defevent__(n)
  end

  def __deftrigger__(event_name, callback_name) when is_atom(callback_name) do
    quote do
      def trigger(unquote(event_name), context) do
        unquote(callback_name).(context)
      end
    end
  end

  def __deftrigger__(event_name, callback_names) when is_list(callback_names) do
    trigger = lc cb inlist callback_names do
      quote do
        unquote(cb).(context)
      end
    end

    quote do
      def trigger(unquote(event_name), context) do
        unquote(trigger)
      end
    end
  end

  def __defevent__(event_name) do
    quote do
      defmacro unquote(event_name)(callback_name) do
        unquote(__MODULE__).__deftrigger__(unquote(event_name), callback_name)
      end
    end
  end
end

defmodule Cruddy do
  import Evented

  defmacro fields(names) do
    Module.put_attribute __CALLER__.module, :fields, names
  end

  defevent :on_create
  # defevent :on_read
  # defevent on_update
  # defevent on_delete

  defmacro defcrudable(name, block) do
    quote do
      defmodule unquote(name) do
        alias __MODULE__, as: Rec

        def save(rec) do
          rec.trigger(:on_create)
        end

        # def save(Rec[__state: :unsaved] = rec) do
        #   rec.trigger(:on_create)
        # end
        #
        # def save(Rec[__state: :saved] = rec) do
        #   rec.trigger(:on_update)
        # end

        import Cruddy
        unquote(block)
        Record.deffunctions @fields ++ [__state: :new], __ENV__
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

    defp foo(rec) do
      IO.puts "foo called"
    end
  end

  defcrudable Post do
    fields [:id, :title, :body]

    on_create [:do_create, :tweet_about_it]
    # on_read :do_read
    # on_update :do_update
    # on_delete :do_delete
    #
    defp do_create(rec) do
      IO.puts "Check it"
    end

    defp tweet_about_it(rec) do
      IO.puts "Tweeted!"
    end
    #
    # defp do_read(rec) do
    # end
    #
    # defp do_update(rec) do
    # end
    #
    # defp do_delete(rec) do
    # end
  end

  post = Post.new
  post = post.title "Kurt stinks"
  post.save
  IO.inspect post.to_keywords
end
