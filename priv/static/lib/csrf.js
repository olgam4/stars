const originalFetch = window.fetch;
window.fetch = function(input, init = {}) {
  const { method } = init
  
  if ((/^(GET|HEAD|OPTIONS)$/.test(method))) return originalFetch(input, init);

  const value = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
  init.headers = {
    ...init.headers,
    'X-Csrf-Token': value
  };
  return originalFetch(input, init);
};