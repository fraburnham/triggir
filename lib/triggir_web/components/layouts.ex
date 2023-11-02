defmodule TriggirWeb.Layouts do
  use TriggirWeb, :html

  embed_templates "layouts/*"

  # attr :breadcrumbs, :list, default: []

  def breadcrumbs(assigns) do
    ~H"""
    <div id="breadcrumb-nav">
      <%= for link <- @breadcrumbs do %>
        <span class="crumb">
          <a href={link.url}>> <%= link.text %></a>
        </span>
      <% end %>
    </div>
    """
  end
end
