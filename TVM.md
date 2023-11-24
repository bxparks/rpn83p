# TVM Algorithms

## Table of Contents

- [TVM Basics](#tvm-algorithms)
- [Interest Rate Conversions](#interest-rate-conversions)
- [TVM Formulas](#tvm-formulas)
- [Small Interest Limits](#small-interest-limits)
    - [CF1 and CF2](#cf1-and-cf2)
    - [N and N0](#n-and-n0)
- [TVM Solver](#tvm-solver)
    - [Number of Solutions](#number-of-solutions)
    - [Taming Overflows](#taming-overflows)
    - [Secant Method](#secant-method)
    - [Initial Guesses](#initial-guesses)
    - [Tolerance](#tolerance)
    - [Maximum Iterations](#maximum-iterations)
    - [Convergence](#convergence)

Notes about the equations and algorithms used by the TVM functions.

## TVM Basics

The Time Value of Money equations and algorithms are described here for
posterity. We use the same sign conventions as most other calculators and
references:

- money received (inflow) is positive
- money paid out (outflow) is negative

The time value of money equation can be represented as Net Present Value (NPV)
or Net Future Value (NFV). They balance the cash flow equation of 5 variables:

```
NFV = PV * (1+i)^N + (1+ip) PMT * [(1+i)^N - 1] / i + FV = 0

NPV = PV + (1+ip) PMT * [1 - (1+i)^(-N)] / i + FV (1+i)^(-N) = 0
```

The variables are:
```
PV = present value
FV = future value
PMT = payment per period
i = interest rate, per payment period
N = number of payment periods
```

The fixed parameter is `p` (aka "begin") which is defined as:
```
p = 0, if payments happen at the end of each period,
  = 1, if payments happen at the beginning of each period.
```

Notice that the `NFV` and `NPV` equations are equivalent to each other through
the relationship:

```
NPV = NFV * (1+i)^N
```

## Interest Rate Conversions

The variable `i` in the `NPV` and `NFV` equations defines the interest rate per
payment period. For most real-life problems, it is more convenient to express
the interest rate per year. The relationship between these quantities are:

```
i = IYR/PYR
```

where:
```
IYR = nominal interest rate per year (without compounding)
PYR = number of payments per year
```

In addition, most real-life problems express the annual interest rate as a
percentage instead of a dimensionless fraction. So `IYR = I%YR / 100`, where
`I%YR` is the nominal interest percentage per year.

## TVM Formulas

In theory, each of the 5 variables can be calculated if the other 4 variables
are known. It turns out 4 of the 5 variables have closed-form analytic solutions
as a function of the other 4. One of them, `i` does not have a closed form
solution, and it must be calculated numerically through iteration.

Here are the 4 closed-form solutions:

```
PV = [-FV - (1+ip) PMT CF2(i)] / CF1(i)

PMT = [-PV CF1(i) - FV] / [(1+ip) CF2(i)]

FV = -(1+ip) PMT CF2(i) - PV CF1(i)

N = log(1+i*N0) / log(1+i)

where:

    CF1(i) = (1+i)^N

    CF2(i) = [(1+i)^N-1]/i

    N0 = -(FV+PV)/[(1+ip) PMT + PV i]
```

I'm not a business or financial expert, so I don't know if `CF1()` and `CF2()`
have common financial names, but I call them "compounding factors":

- `CF1()` is the compounding factor required to convert a Present Value into a
  Future Value after `N` periods, without any intervening payments
- `CF2()` is the compounding factor that incorporates `N` identical payments
- `N0` quantity is roughly the unadjusted number of periods required to reach
  `FV+PV` value at a monthly payment of `PMT`, if the compounding interest `i`
  is ignored. (Thanks to Albert Chan at [TVM formula error in programming
  manual?](https://www.hpmuseum.org/forum/thread-20739-post-179379.html#pid179379)
  for this formulation.)

The term `(1+ip)` appears frequently in these equations. It is either `1` (end)
or `(1+i)` (begin). It accounts for the one extra compounding factor that occurs
for all payments because they were made at the beginning of the payment period
instead of the end.

**Implementation Note**: It turns out that it is slightly more efficient to
calculate both `CF1(i)` and `CF2(i)` at the same time, because certain
intermediate terms common to both can be calculated once and saved for use
later. Also, the `(1+ip)` term is always associated with `CF2(i)`, so the
`compoundingFactors()` routine in the code calculates both `CF1(i)` and
`CF3(i)=(1+ip)CF2(i)` at once.

## Small Interest Limits

When the interest rate `i` is small (say, smaller than 1e-6), special
precautions are needed to ensure that numerical cancellation errors are reduced
so that the correct answers are returned. To accomplish this, we need to take a
side trip to define 2 new functions. These functions are designed to return
accurate values when `x` is very small:

```
expm1(x) = e^x-1

log1p(x) = log(1+x) (natural logarithm)
```

Advanced scientific calculators like the HP-42S have these functions built-in.
On the HP-42S these are called `E^X-` and `LN1+` respectively. The TI-83+ and
TI-84+ calculators do not have these functions. But the TI calculators
have hyperbolic trigonometric functions, and these functions can be rewritten
in terms of hyperbolic functions like this:

```
expm1(x) = e^x-1 = 2 sinh(x/2) e^(x/2), for all x

log1p(x) = log(1+x) = asinh((x/2) (1+1/(1+x))), for (1+x)>0
```

The RPN83P provides the same `E^X-` and `LN1+` menu functions as the HP-42S, but
implements them using the above hyperbolic functions instead.

See [Looking for TVM
formulas](https://www.hpmuseum.org/forum/thread-1012-post-8714.html#pid8714)
(2014) for more info.

### CF1 and CF2

With these functions, we can now define `CF1(i)` and `CF2(i)` as follows:

```
CF1(i) = exp(N log1p(i))

CF2(i) = expm1(N log1p(i)) / i
```

Both of these functions are defined only for `(1+i) > 0`, which makes sense,
because an interest rate of `-1` corresponds to 100% *deflation* over a single
payment period. No additional amount of deflation can deflate faster than that.

There is one more interesting mathematical property to consider. The `CF2(i)`
function is undefined at exactly `i=0`, even when the `expm1()` and `log1p()`
functions are used. But it has a well-defined limit as `i -> 0`:

```
CF2(i) = [(1+i)^N-1]/i -> N, as i -> 0.
```

If we redefine `CF2(i)` at `i=0` to be exactly `N`, then the singularity is
removed, and `CF2(i)` becomes a continuous function of `i` at `i=0`:

```
          expm1(N log1p(i)/i, for i!=0
        /
CF2(i) =
        \
          N, for i=0
```

(In fact, I think `CF2(i)` actually becomes infinitely differentiable at `i=0`.
In other words, I think it becomes an [analytic
function](https://en.wikipedia.org/wiki/Analytic_function)).

### N and N0

The formula for `N` was written in terms of `log(1+x)` so that we can use the
`log1p()` function:

```
N = log(1+i*N0) / log(1+i) =  log1p(i*N0) / log1p(i)
```

Even when we use the `log1p()` function, the equation above cannot be evaluated
at `i=0` due to a division by 0. The solution is to notice that the equation for
`N(i)` has a well-defined limit as `i -> 0`:

```
N(i) -> N0 -> -(FV+PV)/PMT as i->0
```

Therefore, if we define `N(i)` as follows,

```
       log(1+i*N0)/log(1+i), for i!=0,
      /
N(i) =
      \
       -(FV+PV)/PMT, for i=0,
```

then `N(i)` is a continuous function of `i` at `i=0`. (In fact, I think `N(i)`
also becomes infinitely differentiable at `i=0`.).

**Note**: It is possible to enter values of `PV`, `PMT`, `FV` and `i` such that
a negative value of `N` is calculated according to the `N(i)` equation. The
RPN83P currently (v0.7.0) does not flag this condition, and returns the negative
value. Maybe it should test for a negative value and return `TVM No Solution`
error message instead?

## TVM Solver

To solve for the interest rate `i`, we have to use numerical methods to solve
for the root of the `NFV = 0` or `NPV = 0` equation. The **TVM Solver** is the
code that solves for the interest rate `i` in the RPN83P app.

### Number of Solutions

The TVM Solver needs to solve the following equation:

```
NFV(i) = PV * (1+i)^N + (1+ip) PMT * [(1+i)^N - 1] / i + FV = 0
```
for values of `(1+i) > 0`. Most likely, `i` will have an even stricter condition
of`i > 0`.

Recall that the original version of this equation is:

```
NFV(i) = PV * (1+i)^N
    + (1+ip) PMT [(1+i)^(N-1) + (1+i)^(N-2) + ... + (1+i)^1 + (1+i)^0]
    + FV = 0
```

Assuming that `N` is a positive integer `>= 2`, this is a polynomial of degree
`N` with respect to the variable `(1+i)`.

[Albert Chan points
out](https://github.com/thomasokken/plus42desktop/issues/2#issuecomment-1136056901)
that we can use [Descartes' rule of
signs](https://en.wikipedia.org/wiki/Descartes%27_rule_of_signs) to determine
how many roots exist for this equation. The rule states that "if the nonzero
terms of a single-variable polynomial with real coefficients are ordered by
descending variable exponent, then the number of positive roots of the
polynomial is either equal to the number of sign changes between consecutive
(nonzero) coefficients, or is less than it by an even number."

For the `NFV(i)` polynomial, the coefficients from degree `N` to `0` are:

```
degree   coefficient
------   -----------
     N   PV + p PMT
   N-1   PMT
   ...   PMT
     1   PMT
     0   (1-p) PMT + FV
```

As before, `p = 0 (end) or 1 (begin)`. Since all the `PMT` terms are identical,
there are only 3 possibilities for the number of sign changes: 0, 1, or 2.
According to the rule of signs, these are the number of possible solutions:

```
0: no solution
1: exactly one solution
2: no solution or 2 solutions
```

If the TVM Solver finds that the number of sign changes is 0, then it knows
immediately that there are no solutions to the polynomial equation, and it can
let the user know immediately.

The RPN83P code uses the following algorithm to determine there are no sign
changes:

- initialize 2 counters:
    - `numNonZero`: number of non-zero coefficients
    - `sumSign`: sum of the `sign(coef)`, where `sign(coef)` is:
        - 0 for positive, and
        - 1 for negative
        - the `sign(coef)` corresponds directly to the sign bit of a TI-OS
          floating point number
- loop through the coefficients, and update the 2 counters
- if `sumSign == numNonZero` OR `numNonZero == 0`, then there were *no* sign
  changes

The TVM Solver does not check for 1 sign-change or 2 sign-changes, because I am
not sure that there is an easy way to distinguish between "no solution" and "two
solutions". And it does not seem useful to know if there is exactly one solution
or 2 solutions, because we would have to perform the numerical iteration to the
find the root in either case.

### Taming Overflows

Once again, here is the equation that we want the TVM Solver to solve:

```
NFV(i) = PV * (1+i)^N + (1+ip) PMT * [(1+i)^N - 1] / i + FV = 0
```

The TVM Solver must sample different values of `i` and iteratively converge to a
solution. During the search process, it may need to evaluate the `NFV(i)`
equation at relatively large values of `i`, say `i=1` (for 100%).

As [Albert Chan points
out](https://www.hpmuseum.org/forum/thread-20739-post-179371.html#pid179371), if
the `NFV(i)` equation is used directly, the terms may overflow quickly for
reasonable values of `i` when `N` is very large. For example, for a 30-year
mortgage with monthly payments, the number payments is `N=360`.  For a sampled
value of `i=1`, the term `(1+i)^N` is approximately `2e108`, which is larger
than the highest number supported by the TI calculator `9.9999e99`. Note that
the same problem exists if we used the `NPV(i)` equation, but in that case, we
would have an *underflow* problem where the polynomial terms become less than
the `1e-99` limit of the TI-OS.

The solution provided by Albert Chan is brilliant. It uses the fact that when we
are solving for the zeros of an equation, we can divide the equation by an
arbitrary function whose values are `> 0` everywhere, and the roots of the
equation are *unchanged*. Let's define a new term `CFN(i,N)`:

```
CFN(i,N) = CF2(i)/N = [(1+i)^N-1]/Ni
```

(Note that this is slightly different than the `C(i,N)` function defined by
Albert Chan in [TVM formula error in programming
manual?](https://www.hpmuseum.org/forum/thread-20739.html) (2023)) The
`CFN(i,N)` function normalized by `N` compared to `CF2(i)` so that it evaluates
to `1` at `i=0` for all `N`.

Let's divide the `NFV(i)` equation by the `CFN(i,N)` quantity to get a function
called `NPMT(i)`:

```
NPMT(i) = NFV(i) / CFN(i,N)
        = PV (1+i)^N Ni / [(1+i)^N-1] + (1+ip)N*PMT + FV / CFN(i,N)
        = PV (-N)i / [(1+i)^(-N)-1] + (1+ip)N*PMT + FV / CFN(i,N)
        = PV / CFN(i,-N) + (1+ip)N*PMT + FV / CFN(i,N)
```

The last line uses the fact that the `PV` term in the `NPMT(i)` equation is the
same as the `FV` term but with the `N` replaced with `-N`. In other words:

```
CFN(i,-N) = CFN(i,N)/(1+i)^N
```

Solving the roots of `NPMT(i)=0` will yield that exactly the same roots as
solving for `NFV(i)=0`, because the `CFN(i,n)` function is positive for all `i`
over the domain of interest `(1+i)>0`.

Why is `NPMT(i)` better for numerical algorithms? It turns out that the shape of
the `CFN(i,N)` function is exactly what we need to tame the growth of `FV(i)`
and `PV(i)` for small and large `i`:

- For small `i -> 0`:
    - `CFN(i,N) -> 1`
- For large `i`:
    - `CFN(i,N) ~ i^(N-1)/N`
    - `CFN(i,-N) ~ 1/Ni`

This means that each term in the `NPMT(i)` equation either diminishes by a
factor of `i^(N-1)` as `i` becomes large, or grows no faster than a linear
function of `i` as `i` becomes large. When the TVM Solver samples the `NPMT(i)`
equation, there is far less chance of numerical overflow.

(**Note**: The previous analysis assumes that we are interested in values of `i`
when `i>0`. It is theoretically possible for `i` to be a negative number between
-1 and 0, in which case the `1/CNF(i,N)` factor can grow quickly as a power of
`N`. Such cases correspond to deflation (negative inflation rate), so it is
usually safe to look for only solutions where `i>0`.)

The physical interpretation of `NPMT(i)` quantity is interesting, since it is
analogous to the `NPV` or `NFV` quantity. It is the "Net Payment" that has to be
made to satisfy the equation, using a nominal dollar that is *not* adjusted for
inflation or deflation. Each term in the `NPMT(i)` equation has the following
interpreation:

- `PV/CFN(i,-N)`: the nominal value of `N` payments that are equivalent to `PV`
  at the specified interest rate `i`
- `FV/CFN(i,N)`: the nominal value of `N` payments that are equivalent to `FV`
  at the specified interest rate `i`
- `(1+ip)N*PMT`: the nominal value of `N` payments of `PMT`, after normalizing
  all payments to the end of each period

We can perhaps get an intuitive understanding why `NPMT(i)` is less susceptible
to overflow or underflow compared to `NFV(i)` or `NPV(i)`. It tracks the cash
flow in terms of *nominal* currency, not the inflation-adjusted currency at the
beginning or end of the cash flow. The `NPMT(i)` function essentially averages
all 3 terms over the entire duration of the `N` payment periods, instead of
pulling everything to the present or pushing everything to the future.

**Implementation Note**: The `inverseCompoundingFactor()` routine calculates the
reciprocal of `CFN(i,N)`. In other words, it calculates `ICFN(i,N) = 1/CFN(i,N)
= Ni/((1+i)^N-1)` for a slight gain in efficiency by avoiding a division or two.
This makes `ICFN(i,N)` similar to the `C(n)` function given by Albert Chan in
[TVM formula error in programming
manual?](https://www.hpmuseum.org/forum/thread-20739-post-179371.html#pid179371)
(2023), within a factor of `(1+i)^N`, or equivalently, a substitution of `-N`
for `N`.

### Secant Method

There are [many numerical
algorithms](https://en.wikipedia.org/wiki/Root-finding_algorithms) that could be
that can be used to solve for `NPMT(i) = 0`. Some of these are:

- [Bisection method](https://en.wikipedia.org/wiki/Bisection_method)
- [False position method](https://en.wikipedia.org/wiki/Bisection_method)
- [Secant method](https://en.wikipedia.org/wiki/Secant_method)
- [Newton's method](https://en.wikipedia.org/wiki/Newton%27s_method)
- [Halley's method](https://en.wikipedia.org/wiki/Halley%27s_method)

The TVM Solver in RPN83P currently (v0.7.0) uses the *Secant Method*, because it
seems to be a good compromise between simplicity of code and a relatively fast
convergence rate:

1. It has a faster order of convergence (~1.6) than the Bisection method
(linear) with about the same level of complexity.
1. It does not require evaluating the derivative of `NPMT(i)`. The derivative of
`NPMT(i)` is substantially more complicated than `NPMT(i)` which makes it
tedious to translate to Z80 assembly.
1. I have a solid understand the Secant method. I'm not sure I understand the
convergence characteristics of the Newton's method (quadratic convergence) or
Halley's method (cubic convergence).

The convergence of the Secant method seems to be fast enough for get a tolerance
of about 1e-8 within 7-8 iterations.

### Initial Guesses

The Secant method (as well as other root finding methods) requires 2 initial
guesses to be provided. The TVM Solver current (v0.7.0) uses the following
defaults:

- `i0` = 0
- `i1` = 1/PYR, where PYR is the number of payments per year.

The value of `i0` can be set to `0` because all of our various terms and
equations (`ICFN(i,N)`, `NPMT(i)`) have been defined to remove their singularity
at `i=0`. Those functions are now continuous (and probably infinitely
differentiable) at `i=0`.

The value of `i1` is actually specified as `IYR1` of 100%, a nominal yearly rate
of 100%. Most real-life problems will never need to search for an interest rate
higher than 100%/year. The `i1` variable is `IYR/PYR` or `100%/PYR` or `1/PYR`.

The following posts by Albert Chan suggest that there are better initial guess:

- [TVM solve for interest rate,
  revisited](https://www.hpmuseum.org/forum/thread-18359.html) (2022)
- [TVM rate guess](https://github.com/thomasokken/plus42desktop/issues/2) (2022)

However, I have not digested the contents of these posts, so the TVM Solver of
RPN83P does not use any of these more sophisticated guesses.

Successive iterations of the Secant method may push subsequent guesses to extend
beyond the initial `i0` and `i1` guesses. However, the TVM Solver currently
checks if the very first guesses bracket a root with a change in sign of the
`NPMT(i)` function. If no sign change is detected, a `TVM No Solution` error
message is returned.

### Tolerance

Currently (v0.7.0), the TVM Solver iterates until the relative tolerance between
two successive iterations is less than 1e-8. The value of 1e-8 is hardcoded.

To avoid division by zero, the tolerance is calculated as:

```
      |i1 - i0| / |i1|, if |i1|!=0
     /
tol =
     \
      |i1 - i0|, if i1==0

```

I am sure this is not optimal, but I needed a quick way to avoid a division by
zero if `i1` was equal to zero.

Maybe the tolerance limit (1e-8) should be exposed to the user and be
configurable? I believe the HP calculators use the number of significant digits
in its `FIX` mode to determine the tolerance limit. But TI calculator users tend
not to use `FIX` modes, leaving the calculator with the maximum number of
significant digits (i.e. the `FIX(-)` mode). I'm not sure that using the number
of digits from the `FIX` mode is a reasonable mechanism for the RPN83P app.

### Maximum Iterations

To avoid an infinite loop, the maximum iterations used by the TVM Solver is
limited to `TMAX`. By default, `TMAX` is set to 15, but can be configured by the
user. Empirically, the TVM Solver (using the Secant method) seems to converge to
the tolerance of 1e-8 within about 7-8 iterations. So I set the default `TMAX`
to be about double that, which is where the 15 came from.

### Convergence

It is not clear to me that the `NPMT(i)` function is guaranteed to converge
using the Secant method. It is possible that Albert Chan has proven this in one
of his posts, for example [TVM solve for interest rate,
revisited](https://www.hpmuseum.org/forum/thread-18359.html) (2022), but I have
not yet digested these posts.
