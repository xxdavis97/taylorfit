require "./index.styl"
Model = require "../Model"

Transformation = require "./label.json"

ko.components.register "tf-transform",
  template: do require "./index.pug"
  viewModel: ( params ) ->
    unless ko.isObservable params.model
      throw new TypeError "components/transform:
      expects [model] to be observable"

    model = params.model() # now static
    columns = model.columns
    data_fit = model.data_fit
    @transform_index = model.show_transform
    transform_columns = model.transform_columns

    # Check if transform popup should render
    @active = ko.computed ( ) => @transform_index() != undefined

    gen_column = ( label, index ) ->
      cols = columns()
      ncols = cols.length
      transform_col = cols[index]
      transform_name = "#{label}(#{transform_col.name})"
      transform_index = ncols
      return {
        name: transform_name,
        index: transform_index,
        label: label
      }

    # Function updates model transform_columns and associate the transform column to original column
    link_transform_column = ( original_index, transform_index ) ->
      curr_cols = transform_columns()
      curr_cols[original_index] = transform_index
      model.transform_columns(curr_cols)

    @close = ( ) ->
      model.show_transform(undefined)

    @transform_log = ( index ) ->
      transform_col = gen_column(
        Transformation.LOG,
        index
      )
      cols = columns()
      cols.push(transform_col)
      model.transformLog(index)
      # Need to append new column name and connect new column with existing column
      model.columns(cols)
      link_transform_column(index, transform_col.index)
      @close()
    
    @k_order_diff = ( index, k = 1 ) ->
      transform_col = gen_column(
        Transformation.K_ORDER_DIFFERENCE,
        index
      )
      cols = columns()
      cols.push(transform_col)
      model.kOrderTransform({
        "#{index}": true,
        "#{k}": true
      })
      # Need to append new column name and connect new column with existing column
      model.columns(cols)
      link_transform_column(index, transform_col.index)
      @close()

    @standardize = ( index ) ->
      transform_col = gen_column(
        Transformation.STANDARDIZE,
        index
      )
      cols = columns()
      cols.push(transform_col)
      model.transformStandardize(index)
      # Need to append new column name and connect new column with existing column
      model.columns(cols)
      link_transform_column(index, transform_col.index)
      @close()

    @rescale = ( index ) ->
      transform_col = gen_column(
        Transformation.RESCALE,
        index
      )
      cols = columns()
      cols.push(transform_col)
      model.transformRescale(index)
      # Need to append new column name and connect new column with existing column
      model.columns(cols)
      link_transform_column(index, transform_col.index)
      @close()
    
    @transform_index.subscribe ( next ) ->
      if next then adapter.unsubscribeToChanges()
      else adapter.subscribeToChanges()

    return this
