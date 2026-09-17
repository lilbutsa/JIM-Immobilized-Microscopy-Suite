package Jimbob;


import org.apache.commons.math3.fitting.leastsquares.*;
import org.apache.commons.math3.linear.*;
import org.apache.commons.math3.util.Pair;
import org.apache.commons.math3.special.Erf;

import java.util.ArrayList;
import java.util.Arrays;
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

    double[] fitQuadratic(double[] xIn,double[] yIn) {
        //fit a+bx+cx^2
        double x = 0, x2 = 0, x3 = 0, x4 = 0;
        double y = 0, xy = 0, x2y = 0;
        double n = xIn.length;

        for(int i=0;i<xIn.length;i++){
            double xi = xIn[i];
            double xi2 = xi*xi;

            x += xi;
            x2 += xi2;
            x3 += xi2*xi;
            x4 += xi2*xi2;

            y += yIn[i];
            xy += xi*yIn[i];
            x2y += xi2*yIn[i];
        }

        double det =
                n*(x2*x4 - x3*x3)
                        - x*(x*x4 - x3*x2)
                        + x2*(x*x3 - x2*x2);

        double detA =
                y*(x2*x4 - x3*x3)
                        - x*(xy*x4 - x3*x2y)
                        + x2*(xy*x3 - x2*x2y);

        double detB =
                n*(xy*x4 - x3*x2y)
                        - y*(x*x4 - x3*x2)
                        + x2*(x*x2y - xy*x2);

        double detC =
                n*(x2*x2y - xy*x3)
                        - x*(x*x2y - xy*x2)
                        + y*(x*x3 - x2*x2);

        double[] result = new double[3];
        if(det == 0)return result;
        result[0] = detA/det; // a
        result[1] = detB/det; // b
        result[2] = detC/det; // c
        return result;
    }

    static double[] fitPiecewiseConstantLinear(double[] xIn,double[] yIn){
        double[] result = new double[3];//y=a for x<c  and y=a+b(x-c) for x>=c
        double bestSSE = Double.MAX_VALUE;
        double n = xIn.length;

        for(int cCount=0;cCount<xIn.length;cCount++){
            double c = xIn[cCount];
            double x = 0,y = 0,x2 = 0,xy = 0;

            for(int i=0;i<xIn.length;i++){
                double xAfterStep = xIn[i]<c?0:xIn[i]-c;
                x += xAfterStep;
                y += yIn[i];
                x2 += xAfterStep*xAfterStep;
                xy += xAfterStep*yIn[i];
            }

            double denominator = n*x2-x*x;
            double a,b;
            if(Math.abs(denominator)<1.0e-12){
                a = y/n;
                b = 0;
            }
            else{
                a = (x2*y-x*xy)/denominator;
                b = (n*xy-x*y)/denominator;
            }

            double sse = 0;
            for(int i=0;i<xIn.length;i++){
                double xAfterStep = xIn[i]<c?0:xIn[i]-c;
                double residual = yIn[i]-(a+b*xAfterStep);
                sse += residual*residual;
            }

            if(sse<bestSSE){
                bestSSE = sse;
                result[0] = a;
                result[1] = b;
                result[2] = c;
            }
        }
        return result;

    }


    static double[] fitPiecewiseConstantExp(double[] xIn,double[] yIn) {
        //fit a for x<c and a+b(1-exp(-d(x-c))) for x>=c
        //set up jacobian calculation
        MultivariateJacobianFunction model = point -> {
            double a = point.getEntry(0);
            double b = point.getEntry(1);
            double c = point.getEntry(2);
            double d = point.getEntry(3);

            double[] values = new double[xIn.length];
            double[][] jacobian = new double[xIn.length][4];

            for (int i = 0; i < xIn.length; i++) {
                double x = xIn[i];

                if(x<c){
                    values[i] = a;
                    jacobian[i][0] = 1;
                    jacobian[i][1] = 0;
                    jacobian[i][2] = 0;
                    jacobian[i][3] = 0;
                }
                else{
                    double xAfterStep = x-c;
                    double expTerm = Math.exp(-d*xAfterStep);
                    values[i] = a+b*(1-expTerm);
                    jacobian[i][0] = 1;
                    jacobian[i][1] = 1-expTerm;
                    jacobian[i][2] = -b*d*expTerm;
                    jacobian[i][3] = b*xAfterStep*expTerm;
                }
            }

            return new Pair<>(new ArrayRealVector(values), new Array2DRowRealMatrix(jacobian));
        };

        //make initial guess
        double[] initialGuess = new double[4];
        double bestSSE = Double.MAX_VALUE;
        double aSum = 0,aApprox,bApprox,dApprox;
        double yFinal =  yIn[xIn.length-1];



        for(int cCount=1;cCount<xIn.length;cCount++) {
            aSum += yIn[cCount - 1];
            aApprox = aSum / (cCount);
            bApprox = yFinal - aApprox;

            double yval,xysum = 0,ysum = 0;
            if(Math.abs(bApprox)>0.01*Math.abs(aApprox)) {
                for (int i = cCount; i < xIn.length; i++) {
                    yval = 1-(yIn[i] - aApprox) / bApprox;
                    xysum += (xIn[i] - xIn[cCount]) * yval;
                    ysum += yval;
                }
                dApprox = ysum / xysum;//exponent = 1/mean
            } else dApprox = 4/Math.max((xIn[xIn.length-1]-xIn[0]),0.00001);

            double sse = 0;
            for(int i=0;i<xIn.length;i++){
                double xAfterStep = xIn[i]<xIn[cCount]?0:xIn[i]-xIn[cCount];
                double residual = yIn[i]-(aApprox+bApprox*(1-Math.exp(-dApprox*xAfterStep)));
                sse += residual*residual;
            }

            if(sse<bestSSE){
                bestSSE = sse;
                initialGuess[0] = aApprox;
                initialGuess[1] = bApprox;
                initialGuess[2] = xIn[cCount];
                initialGuess[3] = dApprox;
            }
        }


        // 3. Build and solve the least squares problem
        LeastSquaresProblem problem = new LeastSquaresBuilder()
                .model(model)
                .target(yIn)
                .start(initialGuess) // Initial guess for [a, b, c, d]
                .maxEvaluations(100000)
                .maxIterations(100000)
                .build();

        LeastSquaresOptimizer.Optimum optimum = new LevenbergMarquardtOptimizer().optimize(problem);

        // 4. Output results
        double[] result = new double[4];
        RealVector solution = optimum.getPoint();
        for(int i=0;i<4;i++)result[i] = solution.getEntry(i);

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
            yval = (yf-yl)!=0?(yIn[i]-yl)/(yf-yl):0;
            xysum += xIn[i]*yval;
            ysum += yval;
        }
        double[] initialGuess = new double[3];
        initialGuess[0] = yl;//offset
        initialGuess[1] = yf-yl;//height
        if(xysum!=0) initialGuess[2] = ysum/xysum;//exponent = 1/mean
        else if(xIn.length>2) initialGuess[2] = 1/(xIn[xIn.length-1]-xIn[0]);
        else initialGuess[2] = 1;


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
        if(xIn[yIn.length-1] !=0) {
            initialGuess[0] = yIn[yIn.length - 1] / xIn[yIn.length - 1];//polymerisation
            initialGuess[1] = 5.0 / xIn[yIn.length - 1];//nucleation
        } else {
            initialGuess[0] =0;
            initialGuess[1] =1;
        }


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
        if(xIn[yIn.length/2]!=0) {
            initialGuess[0] = yIn[yIn.length / 2] / xIn[yIn.length / 2];//polymerisation
            initialGuess[1] = 5.0 / xIn[yIn.length - 1];//nucleation
        } else{
            initialGuess[0] = 0;
            initialGuess[1] = 1;
        }

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
                // Partial derivative with respect to b: (p/(b (b-n)^2)((1+(t+1/b)(b-n))(b(E^(-n t)-1)-n(E^(-b t)-1))-(b-n)((b t+1)(E^(-n t)-1)+n t)))
                //
                jacobian[i][2] = (p/(b*(b-n)*(b-n))*((1+(x+1/b)*(b-n))*(b*(expTermn-1)-n*(expTermb-1))-(b-n)*((b*x+1)*(expTermn-1)+n*x)));
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


    double[] fitLogNormalNoOffset(double[] xIn, double[] yIn) {
        // fit y = b * [1 / (x*sigma*sqrt(2*pi))] * exp(-(ln(x)-mu)^2 / (2*sigma^2))
        // returns {b, mu, sigma}

        MultivariateJacobianFunction model = point -> {
            double b = point.getEntry(0);
            double mu = point.getEntry(1);

            // Optimize log(sigma), then convert to sigma so sigma is always positive.
            double logSigma = point.getEntry(2);
            double sigma = Math.exp(logSigma);

            double[] values = new double[xIn.length];
            double[][] jacobian = new double[xIn.length][3];

            double sqrt2pi = Math.sqrt(2.0 * Math.PI);

            for (int i = 0; i < xIn.length; i++) {
                double x = xIn[i];

                if (x <= 0) {
                    values[i] = 0;
                    jacobian[i][0] = 0;
                    jacobian[i][1] = 0;
                    jacobian[i][2] = 0;
                    continue;
                }

                double logX = Math.log(x);
                double diff = logX - mu;
                double sigma2 = sigma * sigma;

                double logNorm = Math.exp(-(diff * diff) / (2.0 * sigma2))
                        / (x * sigma * sqrt2pi);

                values[i] = b * logNorm;

                jacobian[i][0] = logNorm;                         // d/db
                jacobian[i][1] = b * logNorm * diff / sigma2;     // d/dmu

                // d/dlogSigma = d/dsigma * sigma
                jacobian[i][2] = b * logNorm * (-1.0 + (diff * diff) / sigma2);
            }

            return new Pair<>(new ArrayRealVector(values), new Array2DRowRealMatrix(jacobian));
        };

        // Initial guess
        double yMax = Arrays.stream(yIn).max().getAsDouble();

        double weightedLogSum = 0;
        double weightSum = 0;

        for (int i = 0; i < xIn.length; i++) {
            if (xIn[i] <= 0) continue;

            double weight = Math.max(yIn[i], 0);
            weightedLogSum += Math.log(xIn[i]) * weight;
            weightSum += weight;
        }

        double muGuess = weightSum > 0
                ? weightedLogSum / weightSum
                : Math.log(xIn[Math.max(0, xIn.length / 2)]);

        double varianceSum = 0;
        for (int i = 0; i < xIn.length; i++) {
            if (xIn[i] <= 0) continue;

            double weight = Math.max(yIn[i], 0);
            double diff = Math.log(xIn[i]) - muGuess;
            varianceSum += weight * diff * diff;
        }

        double sigmaGuess = weightSum > 0 ? Math.sqrt(varianceSum / weightSum) : 1.0;
        if (!Double.isFinite(sigmaGuess) || sigmaGuess <= 0) sigmaGuess = 1.0;

        double[] initialGuess = new double[3];
        initialGuess[0] = yMax;                 // b
        initialGuess[1] = muGuess;              // mu
        initialGuess[2] = Math.log(sigmaGuess); // log(sigma)

        LeastSquaresProblem problem = new LeastSquaresBuilder()
                .model(model)
                .target(yIn)
                .start(initialGuess)
                .maxEvaluations(100000)
                .maxIterations(100000)
                .build();

        LeastSquaresOptimizer.Optimum optimum = new LevenbergMarquardtOptimizer().optimize(problem);

        RealVector solution = optimum.getPoint();

        double[] result = new double[3];
        result[0] = solution.getEntry(0);              // b
        result[1] = solution.getEntry(1);              // mu
        result[2] = Math.exp(solution.getEntry(2));    // sigma

        return result;
    }

    double[] fitNormalNoOffset(double[] xIn, double[] yIn) {
        // fit y = b * [1 / (sigma*sqrt(2*pi))] * exp(-(x-mu)^2 / (2*sigma^2))
        // returns {b, mu, sigma}

        MultivariateJacobianFunction model = point -> {
            double b = point.getEntry(0);
            double mu = point.getEntry(1);

            // Fit log(sigma) so sigma is always positive
            double logSigma = point.getEntry(2);
            double sigma = Math.exp(logSigma);

            double[] values = new double[xIn.length];
            double[][] jacobian = new double[xIn.length][3];

            double sqrt2pi = Math.sqrt(2.0 * Math.PI);

            for (int i = 0; i < xIn.length; i++) {
                double x = xIn[i];
                double diff = x - mu;
                double sigma2 = sigma * sigma;

                double norm = Math.exp(-(diff * diff) / (2.0 * sigma2))
                        / (sigma * sqrt2pi);

                values[i] = b * norm;

                jacobian[i][0] = norm;                         // d/db
                jacobian[i][1] = b * norm * diff / sigma2;     // d/dmu

                // d/dlogSigma = d/dsigma * sigma
                jacobian[i][2] = b * norm * (-1.0 + (diff * diff) / sigma2);
            }

            return new Pair<>(new ArrayRealVector(values), new Array2DRowRealMatrix(jacobian));
        };

        // Initial guess
        double yMax = Arrays.stream(yIn).max().getAsDouble();

        double weightedSum = 0;
        double weightSum = 0;

        for (int i = 0; i < xIn.length; i++) {
            double weight = Math.max(yIn[i], 0);
            weightedSum += xIn[i] * weight;
            weightSum += weight;
        }

        double muGuess = weightSum > 0 ? weightedSum / weightSum : xIn[xIn.length / 2];

        double varianceSum = 0;
        for (int i = 0; i < xIn.length; i++) {
            double weight = Math.max(yIn[i], 0);
            double diff = xIn[i] - muGuess;
            varianceSum += weight * diff * diff;
        }

        double sigmaGuess = weightSum > 0 ? Math.sqrt(varianceSum / weightSum) : 1.0;
        if (!Double.isFinite(sigmaGuess) || sigmaGuess <= 0) sigmaGuess = 1.0;

        double[] initialGuess = new double[3];
        initialGuess[0] = yMax * sigmaGuess * Math.sqrt(2.0 * Math.PI); // b
        initialGuess[1] = muGuess;                                      // mu
        initialGuess[2] = Math.log(sigmaGuess);                         // log(sigma)

        LeastSquaresProblem problem = new LeastSquaresBuilder()
                .model(model)
                .target(yIn)
                .start(initialGuess)
                .maxEvaluations(100000)
                .maxIterations(100000)
                .build();

        LeastSquaresOptimizer.Optimum optimum = new LevenbergMarquardtOptimizer().optimize(problem);

        RealVector solution = optimum.getPoint();

        double[] result = new double[3];
        result[0] = solution.getEntry(0);           // b
        result[1] = solution.getEntry(1);           // mu
        result[2] = Math.exp(solution.getEntry(2)); // sigma

        return result;
    }

    double[] fitNormalCDF(double[] xIn, double[] yIn) {
        // Fit:
        // y = 1/2 * (a + b * erf((x - mu) / (sigma * sqrt(2))))
        //
        // returns {a, b, mu, sigma}

        MultivariateJacobianFunction model = point -> {
            double a = point.getEntry(0);
            double b = point.getEntry(1);
            double mu = point.getEntry(2);

            double sigmaRaw = point.getEntry(3);
            double sigma = Math.abs(sigmaRaw);
            boolean sigmaClamped = false;
            if (sigma < 1.0e-12){
                sigma = 1.0e-12;
                sigmaClamped = true;
            }

            double[] values = new double[xIn.length];
            double[][] jacobian = new double[xIn.length][4];

            double sqrt2 = Math.sqrt(2.0);
            double sqrtPi = Math.sqrt(Math.PI);

            for (int i = 0; i < xIn.length; i++) {
                double x = xIn[i];
                double z = (x - mu) / (sigma * sqrt2);
                double erf = Erf.erf(z);
                double expTerm = Math.exp(-z * z);

                values[i] = 0.5 * (a + b * erf);

                jacobian[i][0] = 0.5;        // d/da
                jacobian[i][1] = 0.5 * erf;  // d/db

                // d/dmu
                jacobian[i][2] = -b * expTerm / (sigma * Math.sqrt(2.0 * Math.PI));

                // d/dsigmaRaw = d/dsigma * sign(sigmaRaw)
                double signSigma = sigmaRaw >= 0 ? 1.0 : -1.0;
                signSigma = sigmaClamped?0:signSigma;
                //jacobian[i][3] = -b * z * expTerm / sqrtPi * signSigma;
                jacobian[i][3] = -b * z * expTerm / (sigma * Math.sqrt(Math.PI)) *signSigma;
            }

            return new Pair<>(new ArrayRealVector(values), new Array2DRowRealMatrix(jacobian));
        };

        double yMin = Arrays.stream(yIn).min().getAsDouble();
        double yMax = Arrays.stream(yIn).max().getAsDouble();

        double aGuess = yMax + yMin;
        double bGuess = yMax - yMin;

        double halfY = 0.5 * (yMin + yMax);
        int midIndex = 0;
        double bestDist = Double.MAX_VALUE;

        for (int i = 0; i < yIn.length; i++) {
            double dist = Math.abs(yIn[i] - halfY);
            if (dist < bestDist) {
                bestDist = dist;
                midIndex = i;
            }
        }

        double muGuess = xIn[midIndex];

        double xMin = Arrays.stream(xIn).min().getAsDouble();
        double xMax = Arrays.stream(xIn).max().getAsDouble();
        double sigmaGuess = (xMax - xMin) / 4.0;

        if (!Double.isFinite(sigmaGuess) || sigmaGuess <= 0) {
            sigmaGuess = 1.0;
        }

        double[] initialGuess = new double[4];
        initialGuess[0] = aGuess;
        initialGuess[1] = bGuess;
        initialGuess[2] = muGuess;
        initialGuess[3] = sigmaGuess;

        LeastSquaresProblem problem = new LeastSquaresBuilder()
                .model(model)
                .target(yIn)
                .start(initialGuess)
                .maxEvaluations(100000)
                .maxIterations(100000)
                .build();

        LeastSquaresOptimizer.Optimum optimum =
                new LevenbergMarquardtOptimizer().optimize(problem);

        RealVector solution = optimum.getPoint();

        double[] result = new double[4];
        result[0] = solution.getEntry(0);                 // a
        result[1] = solution.getEntry(1);                 // b
        result[2] = solution.getEntry(2);                 // mu
        result[3] = Math.abs(solution.getEntry(3));       // sigma

        return result;
    }

    double[] fitLogNormalCDF(double[] xIn, double[] yIn) {
        // Fit:
        // y = 1/2 * (a + b * erf((ln(x) - mu) / (sigma * sqrt(2))))
        //
        // returns {a, b, mu, sigma}
        //
        // Lower asymptote as x -> 0:       0.5 * (a - b)
        // Upper asymptote as x -> infinity: 0.5 * (a + b)

        MultivariateJacobianFunction model = point -> {
            double a = point.getEntry(0);
            double b = point.getEntry(1);
            double mu = point.getEntry(2);

            double sigmaRaw = point.getEntry(3);
            double sigma = Math.abs(sigmaRaw);
            if (sigma < 1.0e-12) sigma = 1.0e-12;

            double[] values = new double[xIn.length];
            double[][] jacobian = new double[xIn.length][4];

            double sqrt2 = Math.sqrt(2.0);
            double sqrtPi = Math.sqrt(Math.PI);

            for (int i = 0; i < xIn.length; i++) {
                double x = xIn[i];

                if (x <= 0) {
                    values[i] = 0.5 * (a - b);
                    jacobian[i][0] = 0.5;
                    jacobian[i][1] = -0.5;
                    jacobian[i][2] = 0.0;
                    jacobian[i][3] = 0.0;
                    continue;
                }

                double z = (Math.log(x) - mu) / (sigma * sqrt2);
                double erf = Erf.erf(z);
                double expTerm = Math.exp(-z * z);

                values[i] = 0.5 * (a + b * erf);

                jacobian[i][0] = 0.5;        // d/da
                jacobian[i][1] = 0.5 * erf;  // d/db

                // d/dmu
                jacobian[i][2] = -b * expTerm / (sigma * Math.sqrt(2.0 * Math.PI));

                // d/dsigmaRaw = d/dsigma * sign(sigmaRaw)
                double signSigma = sigmaRaw >= 0 ? 1.0 : -1.0;
                jacobian[i][3] = -b * z * expTerm / (sigma * sqrtPi) * signSigma;
            }

            return new Pair<>(new ArrayRealVector(values), new Array2DRowRealMatrix(jacobian));
        };

        double yMin = Arrays.stream(yIn).min().getAsDouble();
        double yMax = Arrays.stream(yIn).max().getAsDouble();

        double aGuess = yMax + yMin;
        double bGuess = yMax - yMin;

        double halfY = 0.5 * (yMin + yMax);
        int midIndex = 0;
        double bestDist = Double.MAX_VALUE;

        for (int i = 0; i < yIn.length; i++) {
            if (xIn[i] <= 0) continue;

            double dist = Math.abs(yIn[i] - halfY);
            if (dist < bestDist) {
                bestDist = dist;
                midIndex = i;
            }
        }

        double muGuess = xIn[midIndex] > 0 ? Math.log(xIn[midIndex]) : 0.0;

        double minLogX = Double.MAX_VALUE;
        double maxLogX = -Double.MAX_VALUE;

        for (double x : xIn) {
            if (x <= 0) continue;
            double logX = Math.log(x);
            minLogX = Math.min(minLogX, logX);
            maxLogX = Math.max(maxLogX, logX);
        }

        double sigmaGuess = (maxLogX - minLogX) / 4.0;
        if (!Double.isFinite(sigmaGuess) || sigmaGuess <= 0) {
            sigmaGuess = 1.0;
        }

        double[] initialGuess = new double[4];
        initialGuess[0] = aGuess;
        initialGuess[1] = bGuess;
        initialGuess[2] = muGuess;
        initialGuess[3] = sigmaGuess;

        LeastSquaresProblem problem = new LeastSquaresBuilder()
                .model(model)
                .target(yIn)
                .start(initialGuess)
                .maxEvaluations(100000)
                .maxIterations(100000)
                .build();

        LeastSquaresOptimizer.Optimum optimum =
                new LevenbergMarquardtOptimizer().optimize(problem);

        RealVector solution = optimum.getPoint();

        double[] result = new double[4];
        result[0] = solution.getEntry(0);            // a
        result[1] = solution.getEntry(1);            // b
        result[2] = solution.getEntry(2);            // mu
        result[3] = Math.abs(solution.getEntry(3));  // sigma

        return result;
    }

}



