package org.micromanager.plugins.Poor_Mans_JIM;


import org.apache.commons.math3.analysis.ParametricUnivariateFunction;
import org.apache.commons.math3.fitting.AbstractCurveFitter;
import org.apache.commons.math3.fitting.WeightedObservedPoint;
import org.apache.commons.math3.fitting.leastsquares.LeastSquaresBuilder;
import org.apache.commons.math3.fitting.leastsquares.LeastSquaresProblem;
import org.apache.commons.math3.linear.DiagonalMatrix;
import org.apache.commons.math3.optim.ConvergenceChecker;
import org.apache.commons.math3.optim.SimpleValueChecker;
import org.apache.commons.math3.optim.SimpleVectorValueChecker;

import java.util.ArrayList;
import java.util.Collection;

public class myLeastSquare {

    double yMin, yMax;

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


            double[] initialGuess = new double[3];
            int i = 0;

            double x1 = 0,y1 = 0,x2 = 0;
            double minDist = Double.MAX_VALUE;
            for (WeightedObservedPoint point : points) {
                target[i] = point.getY();
                weights[i] = point.getWeight();
                if(i==0){
                    y1 = target[i];
                    x1 = point.getX();
                }

                if(i>0 && Math.abs(target[i]-(y1/2+yMin/2))<minDist){
                    x2 = point.getX();
                    minDist = Math.abs(target[i]-(y1/2+yMin/2));
                }

                i += 1;
            }

            initialGuess[0] = yMin;
            initialGuess[2] = 0.693/(x2-x1);
            initialGuess[1] = (y1-initialGuess[0])/Math.exp(-initialGuess[2]*x1);


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

        for(int i=0;i<yIn.length;i++)if(yIn[i]>yMin+0.1*yRange && yIn[i]<yMin+0.9*yRange) points.add(new WeightedObservedPoint(1.0, xIn[i], yIn[i]));

        MyFuncFitter fitter = new MyFuncFitter();
        return fitter.fit(points);

    }



}

