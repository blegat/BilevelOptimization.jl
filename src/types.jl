
"""
Convenience alias for a matrix of a sub-type of `Real`
"""
const MT = AbstractMatrix{<:Real}
"""
Convenience alias for a vector of a sub-type of `Real`
"""
const VT = AbstractVector{<:Real}

"""
A bilevel linear optimization problem of the form:
```
min cx^T * x + cy^T * y
s.t. G x + H y <= q
     x_j ∈ [xl_j,xu_j]
     x_j ∈ ℤ ∀ j ∈ Jx
     y ∈ arg min {
        d^T * y + x^T * F * y
        s.t. A x + B y <= b
             y_j ∈ [yl_j,yu_j]
        }
```
Note that integer variables are allowed at the upper level.
"""
struct BilevelLP{V<:VT,M<:MT,MQ<:MT}
    cx::V
    cy::V
    G::M
    H::M
    q::V
    d::V
    A::M
    B::M
    b::V
    nu::Int
    nl::Int
    mu::Int
    ml::Int
    xl::V
    xu::V
    yl::V
    yu::V
    Jx::Vector{Int} # ∀ j ∈ Jx, x[j] is integer
    F::MQ

    function BilevelLP(cx::V,
                       cy::V,
                       G::M,
                       H::M,
                       q::V,
                       d::V,
                       A::M,
                       B::M,
                       b::V,
                       Jx::Vector{Int} = Int[],
                       F::MQ = zeros(length(cx),length(cy))) where {V<:VT,M<:MT,MQ<:MT}
        nu = length(cx)
        nl = length(cy)
        nl == length(d) || DimensionMismatch("Objectives")
        mu = length(q)
        ml = length(b)
        size(A) == (ml,nu) && size(B) == (ml,nl) || DimensionMismatch("Lower constraints")
        size(G) == (mu,nu) && size(H) == (mu,nl) || DimensionMismatch("Higher constraints")
        xl = zeros(nu)
        xu = Inf64 .* ones(nu)
        yl = zeros(nl)
        yu = Inf64 .* ones(nl)
        size(F) == (nu,nl) || DimensionMismatch("Quadratic constraint")
        new{V,M,MQ}(cx,cy,G,H,q,d,A,B,b,nu,nl,mu,ml,xl,xu,yl,yu,Jx,F)
    end
end

"""
VariableType enum distinguishing upper- and lower-level
variables for setting upper and lower bounds
"""
@enum VariableType begin
    lower
    upper
end

"""
Set a lower bound on a lower or higher variable of `bp` depending on `vartype`
"""
function JuMP.setlowerbound(bp::BilevelLP, vartype::VariableType, j::Integer, v::T) where {T<:Real}
    if vartype == lower::VariableType
        bp.yl[j] = v
    else
        bp.xl[j] = v
    end
end

"""
Set an upper bound on a lower or higher variable of `bp` depending on `vartype`
"""
function JuMP.setupperbound(bp::BilevelLP, vartype::VariableType, j::Integer, v::T) where {T<:Real}
    if vartype == lower::VariableType
        bp.yu[j] = v
    else
        bp.xu[j] = v
    end
end
