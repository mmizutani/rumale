# frozen_string_literal: true

require 'svmkit/validation'
require 'svmkit/linear_model/sgd_linear_estimator'
require 'svmkit/base/regressor'

module SVMKit
  module LinearModel
    # SVR is a class that implements Support Vector Regressor
    # with mini-batch stochastic gradient descent optimization.
    #
    # @example
    #   estimator =
    #     SVMKit::LinearModel::SVR.new(reg_param: 1.0, epsilon: 0.1, max_iter: 1000, batch_size: 20, random_seed: 1)
    #   estimator.fit(training_samples, traininig_target_values)
    #   results = estimator.predict(testing_samples)
    #
    # *Reference*
    # 1. S. Shalev-Shwartz and Y. Singer, "Pegasos: Primal Estimated sub-GrAdient SOlver for SVM," Proc. ICML'07, pp. 807--814, 2007.
    class SVR < SGDLinearEstimator
      include Base::Regressor
      include Validation

      # Return the weight vector for SVR.
      # @return [Numo::DFloat] (shape: [n_outputs, n_features])
      attr_reader :weight_vec

      # Return the bias term (a.k.a. intercept) for SVR.
      # @return [Numo::DFloat] (shape: [n_outputs])
      attr_reader :bias_term

      # Return the random generator for performing random sampling.
      # @return [Random]
      attr_reader :rng

      # Create a new regressor with Support Vector Machine by the SGD optimization.
      #
      # @param reg_param [Float] The regularization parameter.
      # @param fit_bias [Boolean] The flag indicating whether to fit the bias term.
      # @param bias_scale [Float] The scale of the bias term.
      # @param epsilon [Float] The margin of tolerance.
      # @param max_iter [Integer] The maximum number of iterations.
      # @param batch_size [Integer] The size of the mini batches.
      # @param optimizer [Optimizer] The optimizer to calculate adaptive learning rate.
      #   If nil is given, Nadam is used.
      # @param random_seed [Integer] The seed value using to initialize the random generator.
      def initialize(reg_param: 1.0, fit_bias: false, bias_scale: 1.0, epsilon: 0.1,
                     max_iter: 1000, batch_size: 20, optimizer: nil, random_seed: nil)
        check_params_float(reg_param: reg_param, bias_scale: bias_scale, epsilon: epsilon)
        check_params_integer(max_iter: max_iter, batch_size: batch_size)
        check_params_boolean(fit_bias: fit_bias)
        check_params_type_or_nil(Integer, random_seed: random_seed)
        check_params_positive(reg_param: reg_param, bias_scale: bias_scale, epsilon: epsilon,
                              max_iter: max_iter, batch_size: batch_size)
        super(reg_param: reg_param, fit_bias: fit_bias, bias_scale: bias_scale,
              max_iter: max_iter, batch_size: batch_size, optimizer: optimizer, random_seed: random_seed)
        @params[:epsilon] = epsilon
      end

      # Fit the model with given training data.
      #
      # @param x [Numo::DFloat] (shape: [n_samples, n_features]) The training data to be used for fitting the model.
      # @param y [Numo::DFloat] (shape: [n_samples, n_outputs]) The target values to be used for fitting the model.
      # @return [SVR] The learned regressor itself.
      def fit(x, y)
        check_sample_array(x)
        check_tvalue_array(y)
        check_sample_tvalue_size(x, y)

        n_outputs = y.shape[1].nil? ? 1 : y.shape[1]
        n_features = x.shape[1]

        if n_outputs > 1
          @weight_vec = Numo::DFloat.zeros(n_outputs, n_features)
          @bias_term = Numo::DFloat.zeros(n_outputs)
          n_outputs.times { |n| @weight_vec[n, true], @bias_term[n] = partial_fit(x, y[true, n]) }
        else
          @weight_vec, @bias_term = partial_fit(x, y)
        end

        self
      end

      # Predict values for samples.
      #
      # @param x [Numo::DFloat] (shape: [n_samples, n_features]) The samples to predict the values.
      # @return [Numo::DFloat] (shape: [n_samples, n_outputs]) Predicted values per sample.
      def predict(x)
        check_sample_array(x)
        x.dot(@weight_vec.transpose) + @bias_term
      end

      # Dump marshal data.
      # @return [Hash] The marshal data about SVR.
      def marshal_dump
        { params: @params,
          weight_vec: @weight_vec,
          bias_term: @bias_term,
          rng: @rng }
      end

      # Load marshal data.
      # @return [nil]
      def marshal_load(obj)
        @params = obj[:params]
        @weight_vec = obj[:weight_vec]
        @bias_term = obj[:bias_term]
        @rng = obj[:rng]
        nil
      end

      private

      def calc_loss_gradient(x, y, weight)
        z = x.dot(weight)
        grad = Numo::DFloat.zeros(@params[:batch_size])
        grad[(z - y).gt(@params[:epsilon]).where] = 1
        grad[(y - z).gt(@params[:epsilon]).where] = -1
        grad
      end
    end
  end
end
