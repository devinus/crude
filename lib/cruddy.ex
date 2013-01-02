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
    List.foldl callbacks, quote(do: context), fn cb, acc ->
      quote do: unquote(cb).(unquote(acc))
    end
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
  defevent :on_exists?

  defmacro fields(names) do
    Module.put_attribute __CALLER__.module, :fields, names
  end

  defmacro primary_key(name) do
    Module.put_attribute __CALLER__.module, :primary_key, name
  end

  defmacro defcrudable(name, block) do
    quote do
      defmodule unquote(name) do
        import Cruddy

        @primary_key :id
        @fields [:id]

        unquote(block)
        Record.deffunctions @fields, __ENV__

        alias __MODULE__, as: Rec

        def find(id) do
          Rec.trigger(:on_read, id)
        end

        def exists?(rec) do
          Rec.trigger(:on_exists?, rec[@primary_key])
        end

        def save(rec) do
          case Rec.trigger(:on_exists?, rec[@primary_key]) do
            true -> rec.trigger(:on_update)
            false -> rec.trigger(:on_create)
          end
        end

        def delete(rec) do
          Rec.trigger(:on_delete, rec[@primary_key])
        end
      end
    end
  end
end
