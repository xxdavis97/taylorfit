
require "./index.styl"
Model = require "../Model"
Combintations = require "combinations-js"

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
<<<<<<< HEAD
    

=======
    @rows = model.data_fit();
>>>>>>> b4f21cbc15a568d91a661193ad0caf4531307bdc
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
          c = Combintations comb_vals, i
          p = Math.pow(base, i)
          accum += c * p
        else
          if i == 0
            accum += 1
          else
            c1 = Combintations comb_vals, i
            p1 = Math.pow(base, i)
            c2 = Combintations comb_vals, i - 1
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
      if next then adapter.unsubscribeToChanges()
      if adapter.addTerm then adapter.subscribeToChanges()
      

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
    
    @getColData = ( ) =>
      master = [];
      k = 0
      rows = @rows;
      while k < rows.length
        if master.length == 0
          rows[k].forEach( (dataPoint) -> 
            master.push([dataPoint])
          )
        else
          i = 0
          j = 0
          while j < rows[k].length
            master[i].push(rows[k][j])
            i++;
            j++;
        k++
      return master;

# calculte tstat solution

    # @mean = (data, popOrSample) =>
    #   total = 0
    #   data.forEach( (point) ->
    #     total += point;
    #   )
    #   if popOrSample
    #     return total / (data.length)
    #   else 
    #     return total / (data.length - 1)

    # @sd = (data) => 
    #   total = 0
    #   data.forEach( (point) ->
    #     total += point
    #   )
    #   mean = total / data.length;
    #   result = Math.sqrt(data.reduce((sq, n) ->
    #       return sq + Math.pow(n-mean,2);
    #     , 0) / (data.length - 1));
    #   return result;

    # @calculateTStat = ( ) =>
    #   colData = @getColData();
    #   terms = model.result_fit().terms
    #   terms.forEach( (term) ->
    #     if term.term.length > 1
    #       x = 0
    #     else
    #       index = term.term[0].index;
    #       exp = term.term[0].exp;
    #       col = colData[index];
    #       calc = [];
    #       col.forEach( (data) ->
    #         calc.push(Math.pow(data,exp));
    #       )
    #       len = calc.length;
    #       total = 0;
    #       calc.forEach( (point) ->
    #         total += point;
    #       )
    #       popMean = total / len;
    #       sampleMean = total / (len - 1);
    #       num = popMean - sampleMean;
    #       sd = Math.sqrt(calc.reduce((sq, n) ->
    #           return sq + Math.pow(n-sampleMean,2);
    #         , 0) / (len - 1));
    #       denom = sd / Math.sqrt(len);
    #       console.log(num/denom);
    #   )
      # console.log(model);
      # console.log(model.result_fit());
      # console.log(model.data_fit());
    # @calculateTStat();
    # @calculateRSq = ( ) ->
    # @calculatePVal = ( ) ->

    @removeLargestPAboveAlpha = ( ) ->
      termsInModel = model.result_fit().terms;
      alpha = model().psig();
      largestP = null;
      termsInModel.forEach( (term) ->
        if (term.stats.pt > alpha && largestP == null)
          largestP = term;
        else if (term.stats.pt > alpha && term.stats.pt > largestP)
          largestP = term;
      )
      if largestP != null
        removedTerm = [[largestP.term[0].index, largestP.term[0].exp, largestP.term[0].lag]];
        index = 0;
        for term in termsInModel
          consolidatedTerm = [[term.term[0].index, term.term[0].exp, term.term[0].lag]]
          if JSON.stringify(consolidatedTerm[0]) == JSON.stringify(removedTerm[0])
            break
          else
            index += 1;
        model.result_fit().terms.splice(index, 1);
        adapter.subscribeToChanges();
        adapter.removeTerm(removedTerm);
        # adapter.unsubscribeToChanges();

    @checkIfTermAboveAlpha = ( ) ->
      termsInModel = model.result_fit().terms;
      alpha = params.model().psig();
      returnVal = false;
      termsInModel.forEach( (term) ->
        if (term.stats.pt > alpha) 
          returnVal = true;
      )
      return returnVal;

    @addSmallestPBelowAlpha = ( ) ->
      alpha = model.psig();
      crossRsq = model.result_cross().stats.Rsq;
      smallestP = null;
      model.candidates().forEach( (candidate) ->
        if (candidate.stats.pt < alpha && smallestP == null && candidate.stats.Rsq > crossRsq)
          smallestP = candidate;
        else if (candidate.stats.pt < alpha && candidate.stats.pt < smallestP && candidate.stats.Rsq > crossRsq)
          smallestP = candidate;
      )
      if smallestP != null
        addedTerm = [[smallestP.term[0].index, smallestP.term[0].exp, smallestP.term[0].lag]];
        model.result_fit().terms.push(smallestP);
        index = 0;
        for candidate in model.candidates()
          consolidatedTerm = [[candidate.term[0].index, candidate.term[0].exp, candidate.term[0].lag]]
          if JSON.stringify(consolidatedTerm[0]) == JSON.stringify(addedTerm[0])
            break
          else
            index += 1;
        model.candidates().splice(index, 1);
        adapter.subscribeToChanges();
        adapter.addTerm(addedTerm);
        # console.log(model);
        # adapter.unsubscribeToChanges();

    @checkIfCandidateToBeAdded = ( ) ->
      crossRsq = model.result_cross().stats.Rsq;
      alpha = model.psig();
      returnVal = false;
      model.candidates().forEach( (candidate) ->
        if (candidate.stats.pt < alpha && candidate.stats.Rsq > crossRsq)
          returnVal = true
      )
      return returnVal;

    @performRemoveCycle = ( ) ->
      while true 
        condition = @checkIfTermAboveAlpha();
        if condition == true 
          @removeLargestPAboveAlpha();
        else
          break
      adapter.subscribeToChanges();

    @performAddCycle = ( ) ->
      while true
        condition = @checkIfCandidateToBeAdded();
        if condition == true
          @addSmallestPBelowAlpha();
        else 
          break
      adapter.subscribeToChanges();

    # console.log(sessionStorage.getItem("onReload") == 'removeCycle');
    # if sessionStorage.getItem('onReload') == 'removeCycle'
    #   console.log("Session remove");
    #   sessionStorage.setItem('onReload', '');
    #   @performRemoveCycle();

    @runAddRemoveCycle = ( ) ->
      @performAddCycle();
      @performRemoveCycle();


    @autofit = ( ) ->
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


      # @performRemoveCycle();
      # Need rsq of candidate to be better than rsq of cross set and need p<alpha then pick lowest p/highest rsq


      # @performAddCycle();
      # @performRemoveCycle();


      # Need to update the pvalues after adding otherwise remove wont work
      # console.log("add");
      # adapter.subscribeToChanges();
      # console.log(adapter);
      # console.log(adapter.listeners["model:fit"][0]);
      # @performAddCycle();
      # console.log(adapter);
      # adapter.listeners["model:fit"][0]("fit");
      # console.log(adapter.listeners["stats"][0]("fit"));
      # console.log(params.model().result_fit());
      # console.log(allstats());
      # adapter.post(postMessage({ type: `model:fit`, data: m.getModel("fit") }))
      @runAddRemoveCycle();



      # setTimeout("", 20000);
      # sessionStorage.setItem('onReload', 'removeCycle');
      # if sessionStorage.getItem('onReload') == 'removeCycle'
      #   console.log("Session remove");
      #   sessionStorage.setItem('onReload', '');
      #   setTimeout(@performRemoveCycle(), 5000);
      # setTimeout(location.reload(), 10000);
      # @performRemoveCycle();

    return this
