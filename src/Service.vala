// TODO remove Object() from constructors

using Gee;

namespace Markets {
  const string BASE_URL = "https://query1.finance.yahoo.com/v1/finance";

  public class RestClient {
    private Soup.Session session;

    public RestClient () {
      this.session = new Soup.Session();
    }

    public async Json.Node fetch (string url) {
      var message = new Soup.Message("GET", url);

      yield this.queue_message(this.session, message);

      // TODO handle error
      // message.status_code == 200

      var body = (string) message.response_body.data;
      return Json.from_string(body);
    }

    public async void queue_message (Soup.Session session, Soup.Message message) {
      SourceFunc async_callback = queue_message.callback;
      session.queue_message (message, () => { async_callback (); });
      yield;
    }
  }

  public class Service : Object {
    private State state;
    private RestClient client;

    public Service (State state) {
      this.state = state;
      this.client = new RestClient();
    }

    public async void search (string query) {
      if (query == null || query.length == 0) {
        this.state.search_results = new ArrayList<Symbol> ();
        return;
      }

      this.state.networkStatus = NetworkStatus.IN_PROGRESS;

      var url = @"$(BASE_URL)/search?q=$query&lang=en-US&region=US&quotesCount=10&newsCount=0&enableFuzzyQuery=false&quotesQueryId=tss_match_phrase_query&enableEnhancedTrivialQuery=true";
      var json = yield this.client.fetch(url);

      var search_results = new ArrayList<Symbol> ();

      var quotes = json.get_object().get_array_member("quotes");
      for (var i = 0; i < quotes.get_length(); i++) {
        var object = quotes.get_object_element(i);
        search_results.add(new Symbol.from_json_object (object));
      }

      this.state.search_results = search_results;

      this.state.networkStatus = NetworkStatus.IDLE;
    }
  }
}
