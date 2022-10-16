defmodule SorteiosWeb.Components do
  use Phoenix.Component

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
                  src="https://tailwindui.com/img/logos/mark.svg?color=indigo&shade=300"
                  alt="Sorteios"
                />
                <h2 class="ml-2 text-2xl font-bold leading-7 text-white sm:truncate sm:text-3xl sm:tracking-tight">
                  Sorteios
                </h2>
              </a>
            </div>
            <!-- Right section on desktop -->
            <div class="hidden lg:ml-4 lg:flex lg:items-center lg:pr-0.5"></div>
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
      <footer>
        <div class="mx-auto max-w-3xl px-4 sm:px-6 lg:max-w-7xl lg:px-8">
          <div class="border-t border-gray-200 py-8 text-center text-sm text-gray-500 sm:text-left">
            <span class="block sm:inline">
              &copy; <%= DateTime.utc_now().year %> Sorteios.
            </span>
            <span class="block sm:inline">Made by lubien.</span>
          </div>
        </div>
      </footer>
    </div>
    """
  end

  def auth_layout(assigns) do
    ~H"""
    <div class="flex min-h-full flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div class="sm:mx-auto sm:w-full sm:max-w-md">
        <img
          class="mx-auto h-12 w-auto"
          src="https://tailwindui.com/img/logos/mark.svg?color=indigo&shade=600"
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
    """
  end
end
