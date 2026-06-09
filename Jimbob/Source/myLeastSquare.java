package org.micromanager.plugins.Poor_Mans_JIM;


import org.apache.commons.math3.fitting.leastsquares.*;
import org.apache.commons.math3.linear.*;
import org.apache.commons.math3.util.Pair;

import java.util.ArrayList;
import java.util.Collection;

public class myLeastSquare {

    double[] fitLinear(double[] xIn,double[] yIn) {
        //fit a+bx
        double x2 = 0,y = 0,x = 0,xy = 0;
        double n = xIn.length;
        for(int i=0;i<xIn.length;i++){
            x2+=xIn[i]*xIn[i];
            y += yIn[i];
            x += xIn[i];
            xy += xIn[i]*yIn[i];

        }
        //Output results
        double[] result = new double[2];
        result[0] = (x2*y-x*xy)/(n*x2-x*x);
        result[1] = (n*xy-x*y)/(n*x2-x*x);
        return result;

    }

    double[] fitExp(double[] xIn,double[] yIn) {
        //fit a+b exp(-c x)
        //set up jacobian calculation
        MultivariateJacobianFunction model = point -> {
            double a = point.getEntry(0);
            double b = point.getEntry(1);
            double c = point.getEntry(2);

            double[] values = new double[xIn.length];
            double[][] jacobian = new double[xIn.length][3];

            for (int i = 0; i < xIn.length; i++) {
                double x = xIn[i];
                double expTerm = Math.exp(-c * x);

                // f(x, a, b)
                values[i] = a+b * expTerm;

                // Partial derivative with respect to a: exp(b * x)
                jacobian[i][0] = 1;
                jacobian[i][1] = expTerm;
                // Partial derivative with respect to b: a * x * exp(b * x)
                jacobian[i][2] = -b * x * expTerm;
            }

            return new Pair<>(new ArrayRealVector(values), new Array2DRowRealMatrix(jacobian));
        };

        //make initial guess
        double ysum=0,xysum=0,yf = yIn[0],yl = yIn[xIn.length-1],yval;
        for(int i=0;i<xIn.length;i++){
            yval = (yIn[i]-yl)/(yf-yl);
            xysum += xIn[i]*yval;
            ysum += yval;
        }
        double[] initialGuess = new double[3];
        initialGuess[0] = yl;//offset
        initialGuess[1] = yf-yl;//height
        initialGuess[2] = ysum/xysum;//exponent = 1/mean


        // 3. Build and solve the least squares problem
        LeastSquaresProblem problem = new LeastSquaresBuilder()
                .model(model)
                .target(yIn)
                .start(initialGuess) // Initial guess for [a, b]
                .maxEvaluations(100000)
                .maxIterations(100000)
                .build();

        LeastSquaresOptimizer.Optimum optimum = new LevenbergMarquardtOptimizer().optimize(problem);

        // 4. Output results
        double[] result = new double[3];
        RealVector solution = optimum.getPoint();
        for(int i=0;i<3;i++)result[i] = solution.getEntry(i);

        return result;

    }

    double[] fitNucPolNoBleach(double[] xIn,double[] yIn) {
        //fit px-p/n(1-exp(-n x))
        //set up jacobian calculation
        MultivariateJacobianFunction model = point -> {
            double p = point.getEntry(0);
            double n = point.getEntry(1);

            double[] values = new double[xIn.length];
            double[][] jacobian = new double[xIn.length][2];

            for (int i = 0; i < xIn.length; i++) {
                double x = xIn[i];
                double expTerm = Math.exp(-n * x);

                // f(x, a, b)
                values[i] = p*x-p/n*(1-expTerm);

                // Partial derivative with respect to p: x-1/n(1-exp(-n x)
                jacobian[i][0] = x-(1-expTerm)/n;
                // Partial derivative with respect to b: p(1-exp(-nt)(1+nt))/n^2
                jacobian[i][1] = p*(1-expTerm*(1+n*x))/(n*n);
            }

            return new Pair<>(new ArrayRealVector(values), new Array2DRowRealMatrix(jacobian));
        };

        //make initial guess

        double[] initialGuess = new double[2];
        initialGuess[0] = yIn[yIn.length-1]/xIn[yIn.length-1];//polymerisation
        initialGuess[1] = 5.0/xIn[yIn.length-1];//nucleation


        // 3. Build and solve the least squares problem
        LeastSquaresProblem problem = new LeastSquaresBuilder()
                .model(model)
                .target(yIn)
                .start(initialGuess) // Initial guess for [a, b]
                .maxEvaluations(100000)
                .maxIterations(100000)
                .build();

        LeastSquaresOptimizer.Optimum optimum = new LevenbergMarquardtOptimizer().optimize(problem);

        // 4. Output results
        double[] result = new double[2];
        RealVector solution = optimum.getPoint();
        for(int i=0;i<2;i++)result[i] = solution.getEntry(i);

        return result;

    }

    double[] fitNucPolGivenBleach(double[] xIn,double[] yIn,double bleachRate) {
        //fit p/(b-n) * (1-exp(-nt)+n/b(exp(-bt)-1))
        //set up jacobian calculation
        MultivariateJacobianFunction model = point -> {
            double p = point.getEntry(0);
            double n = point.getEntry(1);
            double b=bleachRate;

            double[] values = new double[xIn.length];
            double[][] jacobian = new double[xIn.length][2];

            for (int i = 0; i < xIn.length; i++) {
                double x = xIn[i];
                double expTermn = Math.exp(-n * x);
                double expTermb = Math.exp(-b * x);

                // f(x, a, b)
                values[i] = p * (1-expTermn+n/b*(expTermb-1))/(b-n);

                // Partial derivative with respect to p:1/(b-n) * (1-exp(-nt)+n/b(exp(-bt)-1))
                jacobian[i][0] = (1-expTermn+n/b*(expTermb-1))/(b-n) ;
                // Partial derivative with respect to b: p/(b-n)^2 * (exp(-bt)+exp(-nt)*(bt-nt-1))
                jacobian[i][1] = p/((b-n)*(b-n))*(expTermb+expTermn*(b*x-n*x-1));
            }

            return new Pair<>(new ArrayRealVector(values), new Array2DRowRealMatrix(jacobian));
        };

        //make initial guess

        double[] initialGuess = new double[2];
        initialGuess[0] = yIn[yIn.length/2]/xIn[yIn.length/2];//polymerisation
        initialGuess[1] = 5.0/xIn[yIn.length-1];//nucleation


        // 3. Build and solve the least squares problem
        LeastSquaresProblem problem = new LeastSquaresBuilder()
                .model(model)
                .target(yIn)
                .start(initialGuess) // Initial guess for [a, b]
                .maxEvaluations(100000)
                .maxIterations(100000)
                .build();

        LeastSquaresOptimizer.Optimum optimum = new LevenbergMarquardtOptimizer().optimize(problem);

        // 4. Output results
        double[] result = new double[2];
        RealVector solution = optimum.getPoint();
        for(int i=0;i<2;i++)result[i] = solution.getEntry(i);

        return result;

    }

    double[] fitNucPolFitBleach(double[] xIn,double[] yIn) {
        //fit p/(b-n) * (1-exp(-nt)+n/b(exp(-bt)-1))
        //set up jacobian calculation
        MultivariateJacobianFunction model = point -> {
            double p = point.getEntry(0);
            double n = point.getEntry(1);
            double b = point.getEntry(2);

            double[] values = new double[xIn.length];
            double[][] jacobian = new double[xIn.length][3];

            for (int i = 0; i < xIn.length; i++) {
                double x = xIn[i];
                double expTermn = Math.exp(-n * x);
                double expTermb = Math.exp(-b * x);

                // f(x, a, b)
                values[i] = p * (1-expTermn+n/b*(expTermb-1))/(b-n);

                // Partial derivative with respect to p:1/(b-n) * (1-exp(-nt)+n/b(exp(-bt)-1))
                jacobian[i][0] = (1-expTermn+n/b*(expTermb-1))/(b-n) ;
                // Partial derivative with respect to n: p/(b-n)^2 * (exp(-bt)+exp(-nt)*(bt-nt-1))
                jacobian[i][1] = p/((b-n)*(b-n))*(expTermb+expTermn*(b*x-n*x-1));
                // Partial derivative with respect to b: p/(b (b - n)^2) (b (E^(-n t) - 1) - n p (E^(-b t) - 1) - n p (b - n)/b ((1 + b t) E^(-b t) - 1))
                jacobian[i][2] = p/(b*(b-n)*(b-n))*(b*(expTermn - 1) - n*p*(expTermb - 1) - n*p*(b - n)/b*((1 + b*x)*expTermb - 1));
            }

            return new Pair<>(new ArrayRealVector(values), new Array2DRowRealMatrix(jacobian));
        };

        //make initial guess

        double[] initialGuess = new double[3];
        initialGuess[0] = yIn[yIn.length/2]/xIn[yIn.length/2];//polymerisation
        initialGuess[1] = 5.0/xIn[yIn.length-1];//nucleation
        initialGuess[2] = initialGuess[0]/yIn[yIn.length-1];

        // 3. Build and solve the least squares problem
        LeastSquaresProblem problem = new LeastSquaresBuilder()
                .model(model)
                .target(yIn)
                .start(initialGuess) // Initial guess for [a, b]
                .maxEvaluations(100000)
                .maxIterations(100000)
                .build();

        LeastSquaresOptimizer.Optimum optimum = new LevenbergMarquardtOptimizer().optimize(problem);

        // 4. Output results
        double[] result = new double[3];
        RealVector solution = optimum.getPoint();
        for(int j=0;j < 3;j++)result[j] = solution.getEntry(j);
        return result;

    }


}




/*public class myLeastSquare {

    double yMin, yMax,minFitPercent,maxFitPercent;
    double[] initialGuess;


    public class MyFunc implements ParametricUnivariateFunction {
        @Override
        public double value(double t, double... p) {
            return p[0]+p[1]* Math.exp(-p[2] * t);
        }
        @Override
        public double[] gradient(double t, double... p) {
            return new double[]{
                    1,
                    Math.exp(-1.0 * p[2] * t),
                    -t * Math.exp(-1.0 * p[2] * t)
            };
        }

    }


    public class MyFuncFitter extends AbstractCurveFitter {

        @Override
        protected LeastSquaresProblem getProblem(Collection<WeightedObservedPoint> points) {
            final int len = points.size();
            final double[] target = new double[len];
            final double[] weights = new double[len];

            int i = 0;

            for (WeightedObservedPoint point : points) {
                target[i] = point.getY();
                weights[i] = point.getWeight();
                i += 1;
            }

            final AbstractCurveFitter.TheoreticalValuesFunction model = new AbstractCurveFitter.TheoreticalValuesFunction(new MyFunc(), points);

            return new LeastSquaresBuilder().
                    checkerPair((ConvergenceChecker) new SimpleVectorValueChecker(0.01,-1,50000)).
                    maxEvaluations(100000).
                    maxIterations(100000).
                    start(initialGuess).
                    target(target).
                    weight(new DiagonalMatrix(weights)).
                    model(model.getModelFunction(), model.getModelFunctionJacobian()).build();

        }
    }

    double[] fitExp(double[] xIn,double[] yIn) {

        ArrayList<WeightedObservedPoint> points = new ArrayList<>();

        yMin = Double.MAX_VALUE;
        yMax = Double.MIN_VALUE;
        for(int i=0;i<yIn.length;i++){
            if(yIn[i]>yMax)yMax = yIn[i];
            if(yIn[i]<yMin)yMin = yIn[i];
        }
        double yRange = yMax-yMin;

        for(int i=0;i<yIn.length;i++)if(yIn[i]>yMin+minFitPercent/100*yRange && yIn[i]<yMin+maxFitPercent/100*yRange) points.add(new WeightedObservedPoint(1.0, xIn[i], yIn[i]));


        initialGuess = new double[3];
        initialGuess[0] = yMin;
        initialGuess[2] = 0.693/(x2-x1);
        initialGuess[1] = (y1-initialGuess[0])/Math.exp(-initialGuess[2]*x1);

       // MyFuncFitter fitter = new MyFuncFitter();
        //return fitter.fit(points);

        new LeastSquaresBuilder().
                checkerPair((ConvergenceChecker) new SimpleVectorValueChecker(0.01,-1,50000)).
                maxEvaluations(100000).
                maxIterations(100000).
                start(initialGuess).
                target(target).
                weight(new DiagonalMatrix(weights)).
                model(model.getModelFunction(), model.getModelFunctionJacobian()).build();

    }



}*/

