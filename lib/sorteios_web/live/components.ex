defmodule SorteiosWeb.Components do
  use Phoenix.LiveView

  def two_columns_layout(assigns) do
    ~H"""
    <div class="min-h-full">
      <header class="bg-indigo-600 pb-24">
        <div class="mx-auto max-w-3xl px-4 sm:px-6 lg:max-w-7xl lg:px-8">
          <div class="relative flex items-center justify-center py-5 lg:justify-between">
            <!-- Logo -->
            <div class="absolute left-0 flex-shrink-0 lg:static">
              <a href="#">
                <span class="sr-only">Your Company</span>
                <img class="h-8 w-auto" src="https://tailwindui.com/img/logos/mark.svg?color=indigo&shade=300" alt="Your Company">
              </a>
            </div>

            <!-- Right section on desktop -->
            <div class="hidden lg:ml-4 lg:flex lg:items-center lg:pr-0.5">
            </div>

            <!-- Search -->
            <div class="min-w-0 flex-1 px-12 lg:hidden">
              <div class="mx-auto w-full max-w-xs">
                <label for="desktop-search" class="sr-only">Search</label>
                <div class="relative text-white focus-within:text-gray-600">
                  <div class="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
                    <!-- Heroicon name: mini/magnifying-glass -->
                    <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                      <path fill-rule="evenodd" d="M9 3.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zM2 9a7 7 0 1112.452 4.391l3.328 3.329a.75.75 0 11-1.06 1.06l-3.329-3.328A7 7 0 012 9z" clip-rule="evenodd" />
                    </svg>
                  </div>
                  <input id="desktop-search" class="block w-full rounded-md border border-transparent bg-white bg-opacity-20 py-2 pl-10 pr-3 leading-5 text-gray-900 placeholder-white focus:border-transparent focus:bg-opacity-100 focus:placeholder-gray-500 focus:outline-none focus:ring-0 sm:text-sm" placeholder="Search" type="search" name="search">
                </div>
              </div>
            </div>

            <!-- Menu button -->
            <div class="absolute right-0 flex-shrink-0 lg:hidden">
              <!-- Mobile menu button -->
              <button type="button" class="inline-flex items-center justify-center rounded-md bg-transparent p-2 text-indigo-200 hover:bg-white hover:bg-opacity-10 hover:text-white focus:outline-none focus:ring-2 focus:ring-white" aria-expanded="false">
                <span class="sr-only">Open main menu</span>
                <!--
                  Heroicon name: outline/bars-3

                  Menu open: "hidden", Menu closed: "block"
                -->
                <svg class="block h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5" />
                </svg>
                <!--
                  Heroicon name: outline/x-mark

                  Menu open: "block", Menu closed: "hidden"
                -->
                <svg class="hidden h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          </div>
          <div class="hidden border-t border-white border-opacity-20 py-5 lg:block">
            <div class="grid grid-cols-3 items-center gap-8">
              <div class="col-span-2">
              </div>
              <div>

              </div>
            </div>
          </div>
        </div>

        <!-- Mobile menu, show/hide based on mobile menu state. -->
        <div class="lg:hidden">
          <!--
            Mobile menu overlay, show/hide based on mobile menu state.

            Entering: "duration-150 ease-out"
              From: "opacity-0"
              To: "opacity-100"
            Leaving: "duration-150 ease-in"
              From: "opacity-100"
              To: "opacity-0"
          -->
          <div class="fixed inset-0 z-20 bg-black bg-opacity-25" aria-hidden="true"></div>

          <!--
            Mobile menu, show/hide based on mobile menu state.

            Entering: "duration-150 ease-out"
              From: "opacity-0 scale-95"
              To: "opacity-100 scale-100"
            Leaving: "duration-150 ease-in"
              From: "opacity-100 scale-100"
              To: "opacity-0 scale-95"
          -->
          <div class="absolute inset-x-0 top-0 z-30 mx-auto w-full max-w-3xl origin-top transform p-2 transition">
            <div class="divide-y divide-gray-200 rounded-lg bg-white shadow-lg ring-1 ring-black ring-opacity-5">
              <div class="pt-3 pb-2">
                <div class="flex items-center justify-between px-4">
                  <div>
                    <img class="h-8 w-auto" src="https://tailwindui.com/img/logos/mark.svg?color=indigo&shade=600" alt="Your Company">
                  </div>
                  <div class="-mr-2">
                    <button type="button" class="inline-flex items-center justify-center rounded-md bg-white p-2 text-gray-400 hover:bg-gray-100 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-indigo-500">
                      <span class="sr-only">Close menu</span>
                      <!-- Heroicon name: outline/x-mark -->
                      <svg class="h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                      </svg>
                    </button>
                  </div>
                </div>
                <div class="mt-3 space-y-1 px-2">
                  <a href="#" class="block rounded-md px-3 py-2 text-base font-medium text-gray-900 hover:bg-gray-100 hover:text-gray-800">Home</a>
                  <a href="#" class="block rounded-md px-3 py-2 text-base font-medium text-gray-900 hover:bg-gray-100 hover:text-gray-800">Profile</a>
                  <a href="#" class="block rounded-md px-3 py-2 text-base font-medium text-gray-900 hover:bg-gray-100 hover:text-gray-800">Resources</a>
                  <a href="#" class="block rounded-md px-3 py-2 text-base font-medium text-gray-900 hover:bg-gray-100 hover:text-gray-800">Company Directory</a>
                  <a href="#" class="block rounded-md px-3 py-2 text-base font-medium text-gray-900 hover:bg-gray-100 hover:text-gray-800">Openings</a>
                </div>
              </div>
              <div class="pt-4 pb-2">
                <div class="flex items-center px-5">
                  <div class="flex-shrink-0">
                    <img class="h-10 w-10 rounded-full" src="https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" alt="">
                  </div>
                  <div class="ml-3 min-w-0 flex-1">
                    <div class="truncate text-base font-medium text-gray-800">Tom Cook</div>
                    <div class="truncate text-sm font-medium text-gray-500">tom@example.com</div>
                  </div>
                  <button type="button" class="ml-auto flex-shrink-0 rounded-full bg-white p-1 text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2">
                    <span class="sr-only">View notifications</span>
                    <!-- Heroicon name: outline/bell -->
                    <svg class="h-6 w-6" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M14.857 17.082a23.848 23.848 0 005.454-1.31A8.967 8.967 0 0118 9.75v-.7V9A6 6 0 006 9v.75a8.967 8.967 0 01-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 01-5.714 0m5.714 0a3 3 0 11-5.714 0" />
                    </svg>
                  </button>
                </div>
                <div class="mt-3 space-y-1 px-2">
                </div>
              </div>
            </div>
          </div>
        </div>
      </header>
      <main class="-mt-24 pb-8">
        <div class="mx-auto max-w-3xl px-4 sm:px-6 lg:max-w-7xl lg:px-8">
          <h1 class="sr-only">Page title</h1>
          <!-- Main 3 column grid -->
          <div class="grid grid-cols-1 items-start gap-4 lg:grid-cols-3 lg:gap-8">
            <!-- Left column -->
            <div class="grid grid-cols-1 gap-4 lg:col-span-2">
              <section aria-labelledby="section-1-title">
                <h2 class="sr-only" id="section-1-title">Section title</h2>
                <div class="overflow-hidden rounded-lg bg-white shadow">
                  <div class="p-6">
                    <%= render_slot(@inner_block) %>
                  </div>
                </div>
              </section>
            </div>

            <!-- Right column -->
            <div class="grid grid-cols-1 gap-4">
              <section aria-labelledby="section-2-title">
                <h2 class="sr-only" id="section-2-title">Section title</h2>
                <div class="overflow-hidden rounded-lg bg-white shadow">
                  <div class="p-6">
                  <%= render_slot(@right_side) %>
                  </div>
                </div>
              </section>
            </div>
          </div>
        </div>
      </main>
      <footer>
        <div class="mx-auto max-w-3xl px-4 sm:px-6 lg:max-w-7xl lg:px-8">
          <div class="border-t border-gray-200 py-8 text-center text-sm text-gray-500 sm:text-left"><span class="block sm:inline">&copy; 2021 Your Company, Inc.</span> <span class="block sm:inline">All rights reserved.</span></div>
        </div>
      </footer>
    </div>
    """
  end

  def auth_layout(assigns) do
    ~H"""
    <div class="flex min-h-full flex-col justify-center py-12 sm:px-6 lg:px-8">
      <div class="sm:mx-auto sm:w-full sm:max-w-md">
        <img class="mx-auto h-12 w-auto" src="https://tailwindui.com/img/logos/mark.svg?color=indigo&shade=600" alt="Your Company">
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
