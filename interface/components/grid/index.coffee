
require "./index.styl"
Transformation = require "../transform/label.json"

ko.components.register "tf-grid",
  template: do require "./index.pug"
  viewModel: ( params ) ->
    unless ko.isObservable params.model
      throw new TypeError "components/grid:
      expects [model] to be observable"

    unless params.table?
      throw new TypeError "components/grid:
      expects [table] to exist"

    @name = params.name
    @table = params.table
    @hidden = params.hidden
    @start = ko.observable 0
    @end = ko.observable 0
    @precision = ko.precision
    model       = params.model() # now static
    @dependent  = model.dependent
    @hiddenColumns = model.hiddenColumns
    @transform_columns = model.transform_columns
    @cols       = model.columns
    @name       = model["name_#{@table}"]
    @rows       = model["data_#{@table}"]
    @extra      = model["extra_#{@table}"]
    @result     = model["result_#{@table}"]
    # TODO: Button to flip this bool
    @toggle     = true;
    @toggleMean = true;

    @sensitivityColumns  = model.sensitivityColumns
    @sensitivityData   = model.sensitivityData
    @importanceRatioColumns  = model.importanceRatioColumns
    @importanceRatioData   = model.importanceRatioData

    @clear = ( ) =>
      try @rows null
      try @result null
      window.location.reload()
      return undefined

    @histogram = ( index ) ->
      model.show_histogram(index)
      model.data_plotted(@table)

    @histogram_statistic = ( index, statistic ) ->
      if statistic == "sensitivity"
        model.show_histogram("Sensitivity_"+index.toString())
        model.data_plotted(@table)
      if statistic == "importanceRatio"
        model.show_histogram("ImportanceRatio_"+index.toString())
        model.data_plotted(@table)

    @cumulative_distribution = ( index ) ->
      model.show_cumulative_distribution(index)
      model.data_plotted(@table)

    @cumulative_distribution_statistic = ( index, statistic ) ->
      if statistic == "sensitivity"
        model.show_cumulative_distribution("Sensitivity_"+index.toString())
        model.data_plotted(@table)
      if statistic == "importanceRatio"
        model.show_cumulative_distribution("ImportanceRatio_"+index.toString())
        model.data_plotted(@table)


    @autocorrelation = ( index ) ->
      model.show_autocorrelation(index)
      model.data_plotted(@table)

    @autocorrelation_statistic = ( index, statistic ) ->
      if statistic == "sensitivity"
        model.show_autocorrelation("Sensitivity_"+index.toString())
        model.data_plotted(@table)
      if statistic == "importanceRatio"
        model.show_autocorrelation("ImportanceRatio_"+index.toString())
        model.data_plotted(@table)

    @xyplot = ( index ) ->
      model.show_xyplot([index, "Index"])
      model.data_plotted(@table)

    @xyplot_statistic = ( index, statistic ) ->
      if statistic == "sensitivity"
        model.show_xyplot(["Sensitivity_"+index.toString(), "Index"])
        model.data_plotted(@table)
      if statistic == "importanceRatio"
        model.show_xyplot(["ImportanceRatio_"+index.toString(), "Index"])
        model.data_plotted(@table)

    @qqplot = ( index ) ->
      model.show_qqplot(index)
      model.data_plotted(@table)

    @qqplot_statistic = ( index, statistic ) ->
      if statistic == "sensitivity"
        model.show_qqplot("Sensitivity_"+index.toString())
        model.data_plotted(@table)
      if statistic == "importanceRatio"
        model.show_qqplot("ImportanceRatio_"+index.toString())
        model.data_plotted(@table)

    @istimeseries = () ->
      return model.timeseries

    @sensitivity = ( index ) ->
      model.show_sensitivity( index )

    @deleteSensitivity = ( index, type ) ->
      # Delete with either column index or sensitivity index
      if type == "column"
        model.sensitivityColumns().forEach( (column, sensitivityIndex) ->
          if column.index == index
            return model.delete_sensitivity( sensitivityIndex )
        )
      else if type == "sensitivity"
        model.delete_sensitivity( index )

    @hasSensitivity = ( index ) ->
      found = false
      model.sensitivityColumns().forEach( (column) ->
        if column.index == index
          found = true
      )
      return found

    @importanceRatio = ( index ) ->
      model.show_importanceRatio( index )

    @deleteImportanceRatio = ( index, type ) ->
      # Delete with either column index or ratio index
      if type == "column"
        model.importanceRatioColumns().forEach( (column, importanceRatioIndex) ->
          if column.index == index
            return model.delete_importanceRatio( importanceRatioIndex )
        )
      else if type == "importanceRatio"
        model.delete_importanceRatio( index )

    @hasImportanceRatio = ( index ) ->
      found = false
      model.importanceRatioColumns().forEach( (column) ->
        if column.index == index
          found = true
      )
      return found

    # Is hidden if ignored or has transformed column
    @isHidden = ( index ) ->
      return (@hiddenColumns().hasOwnProperty(index) &&
        @hiddenColumns()[index]) ||
        @transform_columns()[index]

    @canDeleteTransformColumn = ( index ) ->
      transformColumns = Object.values(@transform_columns())
      # The index must be a value in transform_columns. It is a transformation of the key
      # And the index must not be a key in transform_columns where value is not undefined.
      # If the value for index key is not undefined, means it has another transform column is dependent on it
      return transformColumns.includes(index) &&
        !@transform_columns()[index] &&
        @result() &&
        !@result().terms.find((term) ->
          term.term.find((t) -> t.index == index)
        )

    @deleteTransformColumn = ( index ) ->
      curr_transform_cols = @transform_columns()
      values = Object.keys(curr_transform_cols)
      values.forEach((v) ->
        if curr_transform_cols[v] == index
          curr_transform_cols[v] = undefined
        else if curr_transform_cols[v] > index
          curr_transform_cols[v] = curr_transform_cols[v] - 1
      )
      curr_transform_cols[index] = undefined
      model.transform_columns(curr_transform_cols)
      # Delete index from columns and data
      cols = @cols()
      cols.splice(index, 1)
      model.columns(cols)
      model.transformDelete({ index: index })

    @showHideColumn = ( shouldHide, index ) ->
      oldCols = @hiddenColumns()
      oldCols[index] = shouldHide
      model.hiddenColumns(oldCols)

    @showTransformColumn = ( index ) ->
      model.show_transform(index)

    @save = ( ) =>
      cols = @cols(); rows = @rows(); extra = @extra()
      means = @mean(); sds = @sd(); mins = @min(); max = @max(); rms = @rms(); med = @med(); first = @firstQuartile();
      third = @thirdQuartile();
      csv = "Mean," + means.join ","
      csv += "\nSD," + sds.join ","
      csv += "\nRMS," + rms.join ","
      csv += "\nMin," + mins.join ","
      csv += "\n25%," + first.join ","
      csv += "\nMed," + med.join ","
      csv += "\n75%," + third.join ","
      csv += "\nMax," + max.join ","
      csv += "\nIndex,"
      csv += @cols().map(( v ) -> v.name).join ","
      if extra
        csv += ",Dependent,Predicted,Residual"
      if @sensitivityColumns().length > 0
        csv += "," + @sensitivityColumns().map((col) -> "Sensitivity "+col.name).join ","
      if @importanceRatioColumns().length > 0
        csv += "," + @importanceRatioColumns().map((col) -> "Importance Ratio "+col.name).join ","
      for row, index in rows
        csv += "\n" + (index + 1).toString() + ","
        csv += row.join ","
        if extra then csv += "," + extra[index].join ","
        if @sensitivityData().length > 0
          csv += "," + @sensitivityData().map((col) -> col[index]).join ","
        if @importanceRatioData().length > 0
          csv += "," + @importanceRatioData().map((col) -> col[index]).join ","

      blob = new Blob [ csv ]
      uri = URL.createObjectURL blob
      link = document.createElement "a"
      link.setAttribute "href", uri
      link.setAttribute "download", "data.csv"
      document.body.appendChild link

      link.click()
      document.body.removeChild link

      return undefined

    @round_cell = ( data ) ->
      if !isNaN(data)
        decimals = @precision()
        +data.toPrecision(decimals)
      else
        data

    @is_k_order_diff = ( col, index ) ->
      col &&
      col.hasOwnProperty("k") &&
      col.k != undefined &&
      index < col.k

    @mean = ( ) ->
      totals = []
      rowLength = @rows().length
      k = 0
      rows = @rows()
      extra = @extra()
      sensitive = @sensitivityData()
      importance = @importanceRatioData()
      while k < rowLength
        if !totals.length
          totals = rows[k].slice(0)
          if extra
            extra[k].forEach( (dataPoint) ->
              totals.push(dataPoint)
            )
          sensitive.forEach( (col) ->
            totals.push(col[0])
          )
          importance.forEach( (col) ->
            totals.push(col[0]);
          )
        else
          i = 0
          j = 0
          while j < rows[k].length
            totals[i] = totals[i] + rows[k][j]
            i++;
            j++;
          j = 0
          if extra
            while j < extra[k].length
              totals[i] = totals[i] + extra[k][j]
              i++;
              j++;
          sensitive.forEach( (col) ->
            iter = 1
            while iter < col.length
              totals[i] = totals[i] + col[iter]
              iter++
            i++
          )
          importance.forEach( (col) ->
            iter = 1
            while iter < col.length
              totals[i] = totals[i] + col[iter]
              iter++
            i++
          )
        k++
      i = 0
      totals.forEach( (total) ->
        totals[i] = total/(rowLength);
        i++;
      )
      return totals;
    @flipMean = ( ) ->
      @toggleMean = !@toggleMean

    @hasMean = ( ) ->
      return @toggleMean;

    @getColData = ( ) ->
      master = [];
      k = 0
      rows = @rows();
      extra = @extra();
      sensitive = @sensitivityData();
      importance = @importanceRatioData();
      while k < rows.length
        if master.length == 0
          rows[k].forEach( (dataPoint) ->
            master.push([dataPoint])
          )
          if extra
            extra[k].forEach( (dataPoint) ->
              master.push([dataPoint])
            )
        else
          i = 0
          j = 0
          while j < rows[k].length
            master[i].push(rows[k][j])
            i++;
            j++;
          j = 0
          if extra
            while j < extra[k].length
              master[i].push(extra[k][j])
              i++;
              j++;
        k++
      sensitive.forEach( (col) ->
        master.push(Object.values(col))
      )
      importance.forEach( (col) ->
        master.push(Object.values(col))
      )
      return master;
    @colData = @getColData();

    @med = ( ) ->
      if (@colData.length == @rows()[0].length)
        @colData = @getColData();
      if @extra()
        @colData = @getColData();
      result = [];
      @colData.forEach( (col) ->
        col = col.sort( (a, b) ->
          return a - b;
        );
        middle = Math.floor((col.length - 1) / 2);
        if col.length % 2
          result.push(col[middle]);
        else
          result.push((col[middle] + col[middle + 1]) / 2.0);
      )
      return result;

    @firstQuartile = ( ) ->
      if (@colData.length == @rows()[0].length)
        @colData = @getColData();
      if @extra()
        @colData = @getColData();
      result = [];
      @colData.forEach( (col) ->
        col = col.sort( (a, b) ->
          return a - b;
        );
        pos = ((col.length) - 1) * .25;
        base = Math.floor(pos);
        rest = pos - base;
        if (col[base+1] != undefined)
          result.push(col[base] + rest * (col[base+1] - col[base]));
        else
          result.push(col[base]);
      )
      return result;

    @thirdQuartile = ( ) ->
      if (@colData.length == @rows()[0].length)
        @colData = @getColData();
      if @extra()
        @colData = @getColData();
      result = [];
      @colData.forEach( (col) ->
        col = col.sort( (a, b) ->
          return a - b;
        );
        pos = ((col.length) - 1) * .75;
        base = Math.floor(pos);
        rest = pos - base;
        if (col[base+1] != undefined)
          result.push(col[base] + rest * (col[base+1] - col[base]));
        else
          result.push(col[base]);
      )
      return result;

    @sd = ( ) =>
      if (@colData.length == @rows()[0].length)
        @colData = @getColData();
      if @extra()
        @colData = @getColData();
      result = []
      means = @mean();
      i = 0;
      @colData.forEach( (col) ->
        mean = means[i];
        result.push(Math.sqrt(col.reduce((sq, n) ->
          return sq + Math.pow(n-mean,2);
        , 0) / (col.length - 1)))
      )
      return result;

    @min = ( ) ->
      min = []
      rowLength = @rows().length
      k = 0
      rows = @rows()
      extra = @extra()
      sensitive = @sensitivityData()
      importance = @importanceRatioData()
      while k < rowLength
        if !min.length
          min = rows[k].slice(0)
          if extra
            extra[k].forEach( (dataPoint) ->
              min.push(dataPoint)
            )
          sensitive.forEach( (col) ->
            min.push(col[0])
          )
          importance.forEach( (col) ->
            min.push(col[0]);
          )
        else
          i = 0
          j = 0
          while j < rows[k].length
            if rows[k][j] < min[i]
              min[i] = rows[k][j]
            i++;
            j++;
          j = 0
          if extra
            while j < extra[k].length
              if extra[k][j] < min[i]
                min[i] = extra[k][j]
              i++;
              j++;
          sensitive.forEach( (col) ->
            iter = 1
            while iter < col.length
              if col[iter] < min[i]
                min[i] = col[iter]
              iter++
            i++
          )
          importance.forEach( (col) ->
            iter = 1
            while iter < col.length
              if col[iter] < min[i]
                min[i] = col[iter]
              iter++
            i++
          )
        k++
      return min;

    @max = ( ) ->
      max = []
      rowLength = @rows().length
      k = 0
      rows = @rows()
      extra = @extra()
      sensitive = @sensitivityData()
      importance = @importanceRatioData()
      while k < rowLength
        if !max.length
          max = rows[k].slice(0)
          if extra
            extra[k].forEach( (dataPoint) ->
              max.push(dataPoint)
            )
          sensitive.forEach( (col) ->
            max.push(col[0])
          )
          importance.forEach( (col) ->
            max.push(col[0]);
          )
        else
          i = 0
          j = 0
          while j < rows[k].length
            if rows[k][j] > max[i]
              max[i] = rows[k][j]
            i++;
            j++;
          j = 0
          if extra
            while j < extra[k].length
              if extra[k][j] > max[i]
                max[i] = extra[k][j]
              i++;
              j++;
          sensitive.forEach( (col) ->
            iter = 1
            while iter < col.length
              if col[iter] > max[i]
                max[i] = col[iter]
              iter++
            i++
          )
          importance.forEach( (col) ->
            iter = 1
            while iter < col.length
              if col[iter] > max[i]
                max[i] = col[iter]
              iter++
            i++
          )
        k++
      return max;

    @rms = ( ) =>
      if (@colData.length == @rows()[0].length)
        @colData = @getColData();
      if @extra()
        @colData = @getColData();
      result = []
      @colData.forEach( (col) ->
        squares = col.map((val) => (val*val));
        sum = squares.reduce((acum, val) => (acum + val));
        mean = sum/col.length;
        result.push(Math.sqrt(mean));
      )
      return result;

    @cols.subscribe ( next ) =>
      if next then adapter.unsubscribeToChanges()
      else adapter.subscribeToChanges()

    @rows.subscribe ( next ) =>
      if next then adapter.unsubscribeToChanges()
      else adapter.subscribeToChanges()

    @precision.subscribe ( next ) =>
      if next then adapter.unsubscribeToChanges()
      else adapter.subscribeToChanges()

    @show_partition = ( ) =>
      console.log "This message"
    return this
