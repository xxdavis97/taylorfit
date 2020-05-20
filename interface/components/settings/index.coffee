
require "./index.styl"
Model = require "../Model"
Combinations = require "combinations-js"

download = ( name, type, content ) ->
  a = document.createElement "a"
  a.href = URL.createObjectURL \
    new Blob [ content ], { type }
  a.download = name

  document.body.appendChild a
  a.click()

  URL.revokeObjectURL a.href
  document.body.removeChild a

ko.components.register "tf-settings",
  template: do require "./index.pug"
  viewModel: ( params ) ->

    unless ko.isObservable params.model
      throw new TypeError "components/options:
      expects [model] to be observable"

    model = params.model() # now static

    @modelResult = model.result_fit
    @candidates = model.candidates
    @crossResult = model.result_cross
    @alpha = model.psig
    @selectedStats = []

    @currModel = model.result_fit();
    @currCandidates = model.candidates();
    @currCross = model.result_cross();
    @currAlpha = model.psig();
    @clicked = false;
    @runRemove = false;
    @keepUpdateMult = true;
    @keepUpdateExp = true;
    @recentMultUpdate = false;
    @recentExpUpdate = false;

    @candidates.subscribe( (r) =>
      if !@clicked
        @currCandidates = r;
    )

    @crossResult.subscribe( (r) =>
      if !@clicked
        @currCross = r;
    )

    @alpha.subscribe( (r) =>
      @currAlpha = r;
    )

    # @rows = model.data_fit();
    @active = model.show_settings

    #model = model.show_settings(true)


    @exponents = model.exponents
    @multiplicands = model.multiplicands
    @lags = model.lags
    @timeseries = model.timeseries
    @candidates = model.candidates
    @psig = model.psig

    @multiplicands_max = ko.observable 0
    @num_terms = ko.observable 0
    ko.computed ( ) =>
      ncols = model.columns().length
      n_lags = 0
      zero_lag = false
      for key, value of @lags()
        if key == "0" and value != false then zero_lag = true
        if value != false then n_lags++
      accum = 0
      i = 0
      e = 0
      for key, value of @exponents()
        if value then e++
      if n_lags == 0 or (n_lags == 1 and zero_lag)
        comb_vals = ncols - 1
        base = e
      else if n_lags == 1 and zero_lag == false
        comb_vals = ncols
        base = e
      else if n_lags > 1 and zero_lag == false
        comb_vals = ncols
        base = e * n_lags
      else
        comb_vals = ncols - 1
        base = e * n_lags
      while i <= @multiplicands()

        if n_lags <= 1 or (zero_lag == false)
          c = Combinations comb_vals, i
          p = Math.pow(base, i)
          accum += c * p
        else
          if i == 0
            accum += 1
          else
            c1 = Combinations comb_vals, i
            p1 = Math.pow(base, i)
            c2 = Combinations comb_vals, i - 1
            p2 = Math.pow(base, i-1) * e * (n_lags - 1)
            accum += (c1 * p1) + (c2 * p2)
        i++
      @num_terms accum


    ko.computed ( ) =>
      active = 0
      zero = false
      ncols = model.columns().length
      for key, value of @lags() when ko.unwrap value
        active++
        zero = true if key is "0"
      unless @timeseries() and active
        @multiplicands_max ncols - 1
      else
        unless zero
          @multiplicands_max ncols * active
        else
          @multiplicands_max (ncols - 1) * active + active - 1
      unless @multiplicands.peek() <= @multiplicands_max()
        @multiplicands @multiplicands_max()


    @timeseries.subscribe ( next ) =>
      @lags { 0: true } unless next


    @active.subscribe (next) ->
      #if unchange then adapter.unsubscribeToChanges()
      #if next then adapter.unsubscribeToChanges()
      adapter.unsubscribeToChanges()
      #if (adapter.addTerm || adapter.removedTerm) then adapter.unsubscribeToChanges()


    @recalculate = ( ) ->
      #if ko.computed(true) then adapter.subscribeToChanges()
      #@active.subscribe (next)
      #if next then adapter.unsubscribeToChanges()
      #if adapter.addTerm then adapter.unsubscribeToChanges()
      #@active.subscribe(next)
      #else adapter.subscribeToChanges()

      condition = @checkIfCandidateToBeAdded();
      if condition == true
        adapter.subscribeToChanges();
        adapter.unsubscribeToChanges();
      else
        adapter.unsubscribeToChanges();







    @download_model = ( ) ->
      model = params.model()
      download (model.id() or "model") + ".tf",
        "application/json", model.out()

    @clear_project = ( ) ->
      @clear_settings()
      params.model null

    @clear_model = ( ) ->
      model.show_settings(false)
      adapter.clear()
      adapter.addTerm([[0, 0, 0]])

      # Update sensitivity columns
      for column in model.sensitivityColumns()
        model.update_sensitivity(column.index)

      # Update importance ratio columns
      for column in model.importanceRatioColumns()
        model.update_importanceRatio(column.index)

    @clear_settings = ( ) ->
      model.exponents({1: true})
      model.multiplicands(1)
      model.lags({0: true})
      model.timeseries(false)
      model.psig(0.05)
      ko.precision(5)
      # Clear the selected stats to the default
      allstats().forEach((stat) => stat.selected(stat.default))
      @clicked = false;

    @updateExponents = () ->
      currExponents = model.exponents();
      if !('2' in currExponents) && @keepUpdateExp
        currExponents['2'] = true;
        model.exponents(currExponents);
        @recentExpUpdate = true;
        @keepUpdateMult = true;
        performAddCycle();
      else if !('-1' in currExponents) && @keepUpdateExp
        currExponents['-1'] = true;
        model.exponents(currExponents);
        @recentExpUpdate = true;
        # @keepUpdateMult = true;
        performAddCycle();
      # else if @keepUpdateExp && Object.keys(currExponents).length < 3
      #   newKey = Math.max(Object.keys(currExponents)) + 1;
      #   currExponents[newKey.toString()] = true;
      #   model.exponents(currExponents);
      #   @recentExpUpdate = true;
        # @keepUpdateMult = true;
        performAddCycle();
      else
        performRemoveCycle();
        @clicked = false;

    @updateMultiplicands = () ->
      currNumMultiplicands = model.multiplicands();
      if @keepUpdateMult && currNumMultiplicands < 2#3
        model.multiplicands(currNumMultiplicands + 1);
        @recentMultUpdate = true;
        @performAddCycle();
      else
        @updateExponents();
        # @clicked = false;

    @removeLargestPAboveAlpha = () ->
      termsInModel = @currModel.terms;
      alpha = @currAlpha;
      largestP = null;
      termsInModel.forEach( (term) ->
        if (term.stats.pt > alpha && largestP == null)
          largestP = term;
        else if (term.stats.pt > alpha && term.stats.pt > largestP)
          largestP = term;
      )
      if largestP != null
        removedTerm = [];
        for term in largestP.term
          innerTerm = [term.index, term.exp, term.lag];
          removedTerm.push(innerTerm);
        adapter.subscribeToChanges();
        adapter.removeTerm(removedTerm);

    @checkIfTermAboveAlpha = ( ) ->
      termsInModel = @currModel.terms;
      alpha = @currAlpha;
      returnVal = false;
      termsInModel.forEach( (term) ->
        if (term.stats.pt > alpha)
          returnVal = true;
      )
      return returnVal;

    @addSmallestPBelowAlpha = () ->
      alpha = @currAlpha;
      crossRsq = @currCross.stats.Rsq;
      smallestP = null;
      @currCandidates.forEach( (candidate) ->
        if (candidate.stats.pt < alpha && smallestP == null && candidate.stats.Rsq > crossRsq)
          smallestP = candidate;
        else if (candidate.stats.pt < alpha && candidate.stats.pt < smallestP && candidate.stats.Rsq > crossRsq)
          smallestP = candidate;
      )
      if smallestP != null
        addedTerm = []
        for term in smallestP.term
          innerTerm = [term.index, term.exp, term.lag];
          addedTerm.push(innerTerm);
        adapter.subscribeToChanges();
        adapter.addTerm(addedTerm);

    @checkIfCandidateToBeAdded = () ->
      # TODO: Check what is clicked and lots of if statements
      crossRsq = @currCross.stats.Rsq;
      crossAdj = @currCross.stats["adjRsq"];
      crossF = @currCross.stats["F"];
      crossErr = @currCross.stats["MaxAbsErr"];
      alpha = @currAlpha;
      stats = @selectedStats
      returnVal = false;
      @currCandidates.forEach( (candidate) ->
        candTruthVal = true;
        stats.forEach( (stat) ->
          if (stat == 'Rsq' && candidate.stats.Rsq <= crossRsq)
            candTruthVal = false;
          else if (stat == 'adjRsq' && candidate.stats["adjRsq"] <= crossAdj)
            candTruthVal = false;
          else if (stat == 'F' && candidate.stats["F"] <= crossF) 
            candTruthVal = false;
          else if (stat == 'Max|Err|' && candidate.stats["MaxAbsErr"] >= crossErr)
            candTruthVal = false;
        )
        if (candidate.stats.pt <= alpha && candTruthVal)
          returnVal = true
      )
      return returnVal;

    @performRemoveCycle = ( ) ->
      condition = @checkIfTermAboveAlpha();
      if condition == true
        @removeLargestPAboveAlpha()
      else
        #update mult and exp then maybe when those are done have @clicked be false in those functions
        @updateMultiplicands();
        @runRemove = false;
      adapter.subscribeToChanges();

    @performAddCycle = ( ) ->
      condition = @checkIfCandidateToBeAdded();
      if model.multiplicands() > 1 && @recentMultUpdate && condition == false
        @keepUpdateMult = false;
      if Object.keys(model.exponents()).length > 1 && @recentExpUpdate && condition == false
        @keepUpdateExp = false;
      if condition == true
        @addSmallestPBelowAlpha();
        @recentMultUpdate = false;
        @recentExpUpdate = false;
      else
        @runRemove = true;
      adapter.subscribeToChanges();

    @runAddRemoveCycle = ( ) ->
      @performAddCycle();
      if @runRemove
        @performRemoveCycle();

    @modelResult.subscribe( (r) =>
      if @clicked
        if JSON.stringify(@currModel) != JSON.stringify(r)
          @currModel = r;
          @candidates.subscribe( (candidateRes) =>
            if JSON.stringify(@currCandidates) != JSON.stringify(candidateRes)
              @currCandidates = candidateRes;
              @runAddRemoveCycle();
              # @crossResult.subscribe( (crossRes) =>
              # if JSON.stringify(@currCross) != JSON.stringify(crossRes)
                  # @currCross = crossRes;
                  # @runAddRemoveCycle();
              # )
          )
      else
        @currModel = r;
    )

    @autofit = ( ) ->
      @clicked = true;
      allstats().forEach((stat) => 
        if (stat.selected()) 
          if (stat.name in ['Rsq','adjRsq','Max|Err|', 'F'])
            @selectedStats.push(stat.name);
      )
      if (@selectedStats.length == 0)
        @selectedStats.push("adjRsq");
      # console.log(model.candidates());
      # console.log(model.columns());
      @performAddCycle();

      # params.model().candidates() represents the potential pool of choices to add to the model from the right panel
      # Can get p(t) and adjR2 with .stats.pt or .stats.adjRsq
      # console.log(params.model().candidates());

      # params.model().result_fit().terms gets you the current terms of the model
      # console.log(params.model().result_fit().terms);

      # params.model().result_fit().terms[index of term].stats gives t and p(t) of the term (P(t) cant be above alpha)
      # console.log(params.model().result_fit().terms[0].stats);

      # params.model().multiplicands() gets you number of multiplicands set
      # console.log(params.model().multiplicands());

      # params.model().exponents() gets you a dictionary with exponents {1: true, 2: true, -1: true} etc.
      # console.log(params.model().exponents());

      # params.model().psig() gives you value of alpha
      # console.log(params.model().psig());

      # Also see something for setMultiplicands and setExponents


    return this
