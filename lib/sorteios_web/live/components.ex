defmodule SorteiosWeb.Components do
  use SorteiosWeb, :component

  def two_columns_layout(assigns) do
    ~H"""
    <div class="min-h-full">
      <header class="bg-indigo-600 pb-24">
        <div class="mx-auto max-w-3xl px-4 sm:px-6 lg:max-w-7xl lg:px-8">
          <div class="relative flex items-center justify-center py-5 lg:justify-between">
            <!-- Logo -->
            <div class="absolute left-0 flex-shrink-0 lg:static">
              <a href="/" class="flex">
                <img
                  class="h-8 w-auto"
                  src={Routes.static_path(SorteiosWeb.Endpoint, "/images/sorteio-logo-white.svg")}
                  alt="Sorteios"
                />
                <h2 class="ml-2 text-2xl font-bold leading-7 text-white sm:truncate sm:text-3xl sm:tracking-tight">
                  Sorteios
                </h2>
              </a>
            </div>
            <!-- Right section on desktop -->
            <div class="hidden lg:ml-4 lg:flex lg:items-center lg:pr-0.5">
              <%= link "Logout", to: Routes.session_path(SorteiosWeb.Endpoint, :delete), method: :delete, class: "mt-3 inline-flex w-full items-center justify-center rounded-md border border-white bg-indigo-600 px-4 py-2 font-medium text-white shadow-sm hover:bg-indigo-700 hover:border-indigo-300 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 sm:mt-0 sm:ml-3 sm:w-auto sm:text-sm" %>
            </div>
          </div>
          <div class="hidden border-t border-white border-opacity-20 py-5 lg:block">
            <div class="grid grid-cols-3 items-center gap-8">
              <div class="col-span-2"></div>
              <div></div>
            </div>
          </div>
        </div>
      </header>
      <main class="-mt-24 pb-8">
        <div class="mx-auto max-w-3xl px-4 sm:px-6 lg:max-w-7xl lg:px-8">
          <!-- Main 3 column grid -->
          <div class="grid grid-cols-1 items-start gap-4 lg:grid-cols-3 lg:gap-8">
            <!-- Left column -->
            <div class="grid grid-cols-1 gap-4 lg:col-span-2">
              <%= render_slot(@inner_block) %>
            </div>
            <!-- Right column -->
            <div class="grid grid-cols-1 gap-4">
              <%= render_slot(@right_side) %>
            </div>
          </div>
        </div>
      </main>
      <.common_footer class="sm:text-left"/>
    </div>
    """
  end

  def auth_layout(assigns) do
    ~H"""
    <div class="flex min-h-full flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div class="sm:mx-auto sm:w-full sm:max-w-md">
        <img
          class="mx-auto h-12 w-auto"
          src={Routes.static_path(SorteiosWeb.Endpoint, "/images/sorteio-logo-black.svg")}
          alt="Your Company"
        />
        <h2 class="mt-6 text-center text-3xl font-bold tracking-tight text-gray-900">Sorteios</h2>
        <p class="mt-2 text-center text-sm text-gray-600">
          Create or join a room
        </p>
      </div>

      <div class="mt-8 sm:mx-auto sm:w-full sm:max-w-md">
        <div class="bg-white py-8 px-4 shadow sm:rounded-lg sm:px-10">
          <%= render_slot(@inner_block) %>
        </div>
      </div>
    </div>

    <.common_footer class=""/>
    """
  end

  def common_footer(assigns) do
    ~H"""
    <footer>
      <div class="mx-auto max-w-3xl px-4 sm:px-6 lg:max-w-7xl lg:px-8">
        <div class={["border-t border-gray-200 py-8 text-sm text-center text-gray-500", @class]}>
          <span class="block sm:inline">
            &copy; <%= DateTime.utc_now().year %> Sorteios.
          </span>
          <span class="block sm:inline">
            Made by <a
              href="https://github.com/lubien"
              target="_blank"
              class="text-purple-500 hover:text-purple-700"
            >Lubien</a>.
          </span>
          <span class="block sm:inline">
            <a
              href="https://github.com/lubien/sorteios"
              target="_blank"
              class="text-purple-500 hover:text-purple-700"
            >GitHub Repo</a>.
          </span>
          <span class="block sm:inline">
            Region <%= System.get_env("FLY_REGION") || "local" %>.
          </span>
        </div>
      </div>
    </footer>
    """
  end
end
