
require "./index.styl"

ko.components.register "tf-settings",
  template: do require "./index.pug"
  viewModel: ( params ) ->

    unless ko.isObservable params.model
      throw new TypeError "components/options:
      expects [model] to be observable"

    model = params.model() # now static

    @active = model.show_settings
    @stats = model.stats
    @exponents = model.exponents
    @multiplicands = model.multiplicands
    @lags = model.lags
    @candidates = model.candidates

    @subscribedToChanges = ko.observable true
    @subscribedToChanges.subscribe ( next ) ->
      if next then adapter.subscribeToChanges()
      else adapter.unsubscribeToChanges()

    @download_dataset = ( ) ->
      model = params.model()
      download (model.id() or "model") + ".csv",
        "type/csv", model.toCSV()

    @download_model = ( ) ->
      model = params.model()
      download (model.id() or "model") + ".tf",
        "application/json", model.toJSON()

    @clear_project = ( ) ->
      params.model null

    @clear_model = ( ) ->
      params.model().result null
      adapter.clear()

    return this
