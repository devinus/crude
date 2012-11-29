defmodule Evented do
  defmacro defevent(event_name) do
    unquote_call = quote unquote: false, do: unquote(callback_name)

    quote do
      defmacro unquote(event_name)(callback_name) do
        quote do
          def trigger(unquote(event_name)) do
            unquote(unquote_call).()
          end
        end
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
  # defevent on_read
  # defevent on_update
  # defevent on_delete

  defmacro defpersistable(name, block) do
    quote do
      defmodule unquote(name) do
        def save(rec) do
          rec.trigger(:on_create)
        end

        import Cruddy
        unquote(block)
        Record.deffunctions @fields, __ENV__
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

    defp foo do
      IO.puts "foo called"
    end
  end

  defpersistable Post do
    fields [:id, :title, :body]

    on_create :do_create
    # on_read :do_read
    # on_update :do_update
    # on_delete :do_delete
    #
    defp do_create do
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

  Thing.trigger(:some_event)
  #
  # post = Post.new
  # post.save
end
