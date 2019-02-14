function test_alg_morphism_char_0(A, B, AtoB, BtoA)
  @test iszero(AtoB(zero(A)))
  @test iszero(BtoA(zero(B)))
  @test isone(AtoB(one(A)))
  @test isone(BtoA(one(B)))

  for i = 1:5
    c = rand(A, -10:10)
    d = rand(A, -10:10)
    @test BtoA(AtoB(c)) == c
    @test BtoA(AtoB(d)) == d
    @test AtoB(c + d) == AtoB(c) + AtoB(d)
    @test AtoB(c*d) == AtoB(c)*AtoB(d)

    e = rand(B, -10:10)
    f = rand(B, -10:10)
    @test AtoB(BtoA(e)) == e
    @test AtoB(BtoA(f)) == f
    @test BtoA(e + f) == BtoA(e) + BtoA(f)
    @test BtoA(e*f) == BtoA(e)*BtoA(f)
  end
end

function test_alg_morphism_char_p(A, B, AtoB, BtoA)
  @test iszero(AtoB(zero(A)))
  @test iszero(BtoA(zero(B)))
  @test isone(AtoB(one(A)))
  @test isone(BtoA(one(B)))

  for i = 1:5
    c = rand(A)
    d = rand(A)
    @test BtoA(AtoB(c)) == c
    @test BtoA(AtoB(d)) == d
    @test AtoB(c + d) == AtoB(c) + AtoB(d)
    @test AtoB(c*d) == AtoB(c)*AtoB(d)

    e = rand(B)
    f = rand(B)
    @test AtoB(BtoA(e)) == e
    @test AtoB(BtoA(f)) == f
    @test BtoA(e + f) == BtoA(e) + BtoA(f)
    @test BtoA(e*f) == BtoA(e)*BtoA(f)
  end
end

@testset "Change of ring" begin

  # Restrict from number field to Q
  Qx, x = FlintQQ["x"]
  f = x^3 - 2
  K, a = number_field(f, "a")

  A = AlgAss(MatrixAlgebra(K, 2))
  B, AtoB, BtoA = Hecke.restrict_scalars(A, FlintQQ)
  @test base_ring(B) == FlintQQ
  @test dim(B) == dim(A)*degree(K)

  test_alg_morphism_char_0(A, B, AtoB, BtoA)

  # Extend to K again
  C, BtoC, CtoB = Hecke._as_algebra_over_center(B)
  @test isisomorphic(K, base_ring(C))[1]
  @test dim(C) == dim(A)

  test_alg_morphism_char_0(B, C, BtoC, CtoB)

  # Restrict from number field to number field
  g = x^9 - 15x^6 - 87x^3 - 125
  L, b = number_field(g, "b")
  KtoL = NfToNfMor(K, L, -2//45*b^7 + 7//9*b^4 + 109//45*b)

  A = AlgAss(MatrixAlgebra(L, 2))
  B, AtoB, BtoA = Hecke.restrict_scalars(A, KtoL)
 
  @test base_ring(B) == K
  @test dim(B) == dim(A)*div(degree(L), degree(K))

  test_alg_morphism_char_0(A, B, AtoB, BtoA)

  # Restrict from F_q to F_p
  Fp = GF(7)
  Fq, a = FiniteField(7, 3, "a")

  A = AlgAss(MatrixAlgebra(Fq, 2))
  B, AtoB, BtoA = Hecke.restrict_scalars(A, Fp)
  @test base_ring(B) == Fp
  @test dim(B) == dim(A)*degree(K)

  test_alg_morphism_char_p(A, B, AtoB, BtoA)

  # Extend to Fq again
  C, BtoC, CtoB = Hecke._as_algebra_over_center(B)
  @test characteristic(base_ring(C)) == characteristic(Fq)
  @test degree(base_ring(C)) == degree(Fq)
  @test dim(C) == dim(A)

  test_alg_morphism_char_p(B, C, BtoC, CtoB)
end

# n = dim(A)^2 = dim(B)^2
function test_mat_alg_morphism(AtoB::Hecke.AbsAlgAssMor, n::Int)
  A = domain(AtoB)
  B = codomain(AtoB)

  test_alg_morphism_char_p(A, B, AtoB, inv(AtoB))

  sum_of_diag = AtoB\B[1]
  for i = 2:n
    sum_of_diag += AtoB\B[(i - 1)*n + i]
  end
  @test isone(sum_of_diag)

  # B[(i - 1)*n + j]*B[(k - 1)*n + l] == B[(i - 1)*n + l], if j == k, and 0, otherwise
  for i = 1:n
    iN = (i - 1)*n
    for j = 1:n
      ij = iN + j
      for k = 1:n
        kn = (k - 1)*n
        for l = 1:n
          if j == k
            @test AtoB\(B[ij]*B[kn + l]) == AtoB\B[iN + l]
          else
            @test iszero(AtoB\(B[ij]*B[kn + l]))
          end
        end
      end
    end
  end
end

@testset "Matrix Algebra" begin
  Fp = GF(7)
  Fq, a = FiniteField(7, 2, "a")

  A = AlgAss(MatrixAlgebra(Fq, 3))
  B, AtoB = Hecke._as_matrix_algebra(A)
  @test dim(B) == dim(A)

  test_mat_alg_morphism(AtoB, 3)

  G = PermutationGroup(4)
  A = AlgAss(AlgGrp(Fp, G))[1]
  Adec = Hecke.decompose(A)

  i = 2
  B = Adec[1][1]
  while dim(B) != 9
    B = Adec[i][1]
    i += 1
  end

  C, BtoC = Hecke._as_matrix_algebra(B)

  test_mat_alg_morphism(BtoC, 3)

  i = 2
  B = Adec[1][1]
  while dim(B) != 4
    B = Adec[i][1]
    i += 1
  end

  C, BtoC = Hecke._as_matrix_algebra(B)

  test_mat_alg_morphism(BtoC, 2)
end

@testset "Radical" begin
  G = PermutationGroup(4)

  Fp = GF(2)
  A = AlgAss(AlgGrp(Fp, G))[1]
  @test nrows(basis_mat(Hecke.radical(A), false)) == 19

  Fp = GF(fmpz(2))
  A = AlgAss(AlgGrp(Fp, G))[1]
  @test nrows(basis_mat(Hecke.radical(A), false)) == 19

  Fq, a = FiniteField(2, 2, "a")
  A = AlgAss(AlgGrp(Fq, G))[1]
  @test nrows(basis_mat(Hecke.radical(A), false)) == 19

  Fq, a = FiniteField(fmpz(2), 2, "a")
  A = AlgAss(AlgGrp(Fp, G))[1]
  @test nrows(basis_mat(Hecke.radical(A), false)) == 19

  G = PermutationGroup(3)

  Fp = GF(13)
  A = AlgAss(AlgGrp(Fp, G))[1]
  @test nrows(basis_mat(Hecke.radical(A), false)) == 0

  Fp = GF(fmpz(13))
  A = AlgAss(AlgGrp(Fp, G))[1]
  @test nrows(basis_mat(Hecke.radical(A), false)) == 0


  Fq, a = FiniteField(13, 2, "a")
  A = AlgAss(AlgGrp(Fq, G))[1]
  @test nrows(basis_mat(Hecke.radical(A), false)) == 0

  Fq, a = FiniteField(fmpz(13), 2, "a")
  A = AlgAss(AlgGrp(Fp, G))[1]
  @test nrows(basis_mat(Hecke.radical(A), false)) == 0
end