defmodule InboxManagerWeb.LoginLive.Index do
  use InboxManagerWeb, :login_live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="max-w-xl w-full bg-white p-14 rounded-2xl shadow-2xl border border-gray-100">
        <h3 class="mb-2 text-center text-lg font-light text-gray-500">Welcome back!</h3>
        <h2 class="mb-6 text-center text-3xl font-extrabold text-gray-900">
          Sign in to your account
        </h2>
        <.link href="/auth/google">
          <.button class="w-full flex items-center justify-center gap-3 mb-4">
            <svg class="w-5 h-5" viewBox="0 0 48 48">
              <g>
                <path
                  fill="#4285F4"
                  d="M44.5 20H24v8.5h11.7C34.7 32.9 30.1 36 24 36c-6.6 0-12-5.4-12-12s5.4-12 12-12c3.1 0 5.9 1.1 8.1 2.9l6.1-6.1C34.5 6.5 29.6 4 24 4 12.9 4 4 12.9 4 24s8.9 20 20 20c11 0 19.7-8 19.7-20 0-1.3-.1-2.7-.2-4z"
                />
                <path
                  fill="#34A853"
                  d="M6.3 14.7l7 5.1C15.5 16.1 19.4 13 24 13c3.1 0 5.9 1.1 8.1 2.9l6.1-6.1C34.5 6.5 29.6 4 24 4c-7.2 0-13.3 4.1-16.7 10.7z"
                />
                <path
                  fill="#FBBC05"
                  d="M24 44c5.6 0 10.5-1.9 14.3-5.1l-6.6-5.4C29.7 35.5 27 36.5 24 36.5c-6.1 0-10.7-4.1-12.5-9.6l-7 5.4C7.7 39.9 15.2 44 24 44z"
                />
                <path
                  fill="#EA4335"
                  d="M44.5 20H24v8.5h11.7c-1.1 3.1-4.1 5.5-7.7 5.5-4.6 0-8.4-3.8-8.4-8.5s3.8-8.5 8.4-8.5c2.5 0 4.7.9 6.3 2.4l6.1-6.1C34.5 6.5 29.6 4 24 4c-7.2 0-13.3 4.1-16.7 10.7z"
                />
              </g>
            </svg>
            Continue with Google
          </.button>
        </.link>

        <p class="text-center text-xs text-gray-400 mt-6 font-light">
          By signing up, you agree to our
          <a href="https://yourdomain.com/terms" target="_blank" class="underline hover:text-blue-600">
            terms of service
          </a>
          and <a
            href="https://yourdomain.com/privacy"
            target="_blank"
            class="underline hover:text-blue-600"
          >privacy policy</a>.
        </p>
      </div>
    </div>
    """
  end
end
