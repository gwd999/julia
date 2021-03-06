#ISCLOSE Check for nearly equal values.
#   ISCLOSE(x::T1, y::T2) checks if x and y are nearly equal. The default tolerance is
#   determined by the types. If tol = max(eps(T1), eps(T2)), then the values need to be
#   within sqrt(tol)+tol^(1/3)*max(abs(x), abs(y)).
#
#   ISCLOSE(x, y, rtol, atol) provides specific values in place of tol^(1/3) and sqrt(tol),
#   respectively.
#
#   ISCLOSE(x::T1, y::T2) where T1<:Integer and T2<:Integer is the same as ISEQUAL.
function isclose(x, y, rtol, atol)
    if isinf(x) || isinf(y)
        return x == y
    end
    abs(x-y) <= atol+rtol.*max(abs(x), abs(y))
end

#ISCLOSEN Check for nearly equal values, treating NaNs as mutually equal.
#   ISCLOSEN(x, y, ...) checks if x and y are nearly equal in the same way as ISCLOSE, but
#   allowing NaNs to evaluate as equal. This is useful if two methods of computing the same
#   values are being verified against one another, and that computation can produce NaNs.
#
#   ISCLOSEN(x, y, ...) gives the same results as ISCLOSE(x, y, ...) if neither x nor
#   y contain NaN values.
isclosen(x, y, rtol, atol) = isclose(x, y, rtol, atol) || (isnan(x) && isnan(y))

for fun in (:isclose, :isclosen)
    @eval begin
        function ($fun){T1<:Float, T2<:Float}(x::T1, y::T2)
            tol = max(eps(T1), eps(T2))
            ($fun)(x, y, tol^(1/3), sqrt(tol))
        end
        ($fun){T1<:Integer, T2<:Float}(x::T1, y::T2) = ($fun)(float(x), y)
        ($fun){T1<:Float, T2<:Integer}(x::T1, y::T2) = ($fun)(x, float(y))

        ($fun)(X::AbstractArray, y::Number) = map(x -> ($fun)(x, y), X)
        ($fun)(x::Number, Y::AbstractArray) = map(y -> ($fun)(y, x), Y)

        function ($fun)(X::AbstractArray, Y::AbstractArray)
            if size(X) != size(Y)
                error("Arrays must have the same sizes (first is $(size(X)), second is $(size(Y))).")
            end
            Z = similar(X, Bool)
            for i in 1:numel(X)
                Z[i] = ($fun)(X[i], Y[i])
            end
            Z
        end
    end
end

# For integers, isclose() is just isequal() unless you specify nondefault tolerances.
isclose{T1<:Integer, T2<:Integer}(x::T1, y::T2) = isequal(x, y)
#isclosen() doesn't apply to two Integer types, since typeof(NaN)<:Float

#ISEQUALN Check for equality, treating NaNs as mutually equal.
#   ISEQUALN(x, y) gives the same results as ISEQUAL(x, y), unless both x and y are NaN
#   values. In this case, ISEQUALN(x, y) returns true instead of false.
isequaln(x, y) = isequal(x, y) || (isnan(x) && isnan(y))