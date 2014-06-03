class HBase
class Scoped
# Basic data aggregation with coprocessor based on AggregateImplementation
# @author Junegunn Choi <junegunn.c@gmail.com>
module Aggregation
  module Admin
    # Enables aggregation support for the table (asynchronous)
    # @return [nil]
    def enable_aggregation
      cpc = 'org.apache.hadoop.hbase.coprocessor.AggregateImplementation'
      add_coprocessor cpc unless has_coprocessor?(cpc)
    end

    # Enables aggregation support for the table (synchronous)
    # @return [nil]
    def enable_aggregation! &block
      cpc = 'org.apache.hadoop.hbase.coprocessor.AggregateImplementation'
      add_coprocessor! cpc, &block unless has_coprocessor?(cpc)
    end

    # Disables aggregation support for the table (asynchronous)
    # @return [nil]
    def disable_aggregation
      cpc = 'org.apache.hadoop.hbase.coprocessor.AggregateImplementation'
      remove_coprocessor cpc if has_coprocessor?(cpc)
    end

    # Disables aggregation support for the table (synchronous)
    # @return [nil]
    def disable_aggregation! &block
      cpc = 'org.apache.hadoop.hbase.coprocessor.AggregateImplementation'
      remove_coprocessor! cpc, &block if has_coprocessor?(cpc)
    end
  end

  # Performs aggregation with coprocessor
  # @param [Symbol] op Aggregation type: :sum, :min, :max, :avg, :std, :row_count
  # @param [Symbol, org.apache.hadoop.hbase.coprocessor.ColumnInterpreter] type
  #   Column type (only :fixnum is supported as of now) or ColumnInterpreter object used to decode the value
  def aggregate op, type = :fixnum
    check_closed

    aggregation_impl op, type
  end

private
  def aggregation_impl method, type
    raise ArgumentError.new("No column specified") if method != :row_count && @project.empty?

    @@with_byte_array_name ||=
      org.apache.hadoop.hbase.client.coprocessor.AggregationClient.
      java_class.java_instance_methods.select { |m| m.name == 'sum' }.
      map { |m| m.argument_types.first }.include?(''.to_java_bytes.java_class)

    @aggregation_client ||= AggregationClient.new(table.config)
    @aggregation_client.send(
      method,
      @@with_byte_array_name ? Util.to_bytes(table.name) : htable,
      column_interpreter_for(type),
      filtered_scan)
  end

  def column_interpreter_for type
    case type
    when :fixnum, :long
      LongColumnInterpreter.new
    when org.apache.hadoop.hbase.coprocessor.ColumnInterpreter
      type
    else
      raise ArgumentError, "Column interpreter for #{type} not implemented."
    end
  end
end#Aggregation
end#Scoped
end#HBase

