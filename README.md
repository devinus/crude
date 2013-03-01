# CRUDE (Create, Read, Update, Delete, Exists)

```elixir
defpersistable Post do
  fields [:id, :title, :body]

  on_create :do_create
  on_read :do_read
  on_update :do_update
  on_delete :do_delete

  defp do_create(post) do
    :ets.insert_new(:posts, post)
  end

  defp do_read(id) do
    :ets.lookup(:posts, id)
  end

  defp do_update(post) do
    :ets.insert(:posts, post)
  end

  defp do_delete(id) do
    :ets.delete(:posts, id)
  end
end

post = Post.new
post = post.title("Kurt stinks").body("No, really. He does.")
post.save
```
