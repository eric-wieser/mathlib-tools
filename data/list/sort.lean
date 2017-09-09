/-
Copyright (c) 2016 Jeremy Avigad. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Jeremy Avigad

Insertion sort and merge sort.
-/
import data.list.perm
open list.perm

namespace list

section sorted
universe variable uu
variables {α : Type uu} (r : α → α → Prop)

def sorted : list α → Prop
| []       := true
| (a :: l) := sorted l ∧ ∀ b ∈ l, r a b

theorem sorted_nil : sorted r nil := trivial

theorem sorted_singleton (a : α) : sorted r [a] :=
⟨sorted_nil r, λ b h, absurd h (not_mem_nil b)⟩

theorem sorted_of_sorted_cons {a : α} {l : list α} (h : sorted r (a :: l)) : sorted r l :=
h.left

theorem forall_mem_rel_of_sorted_cons {a : α} {l : list α} (h : sorted r (a :: l)) :
  ∀ b ∈ l, r a b :=
h.right

theorem sorted_cons {a : α} {l : list α} (h₁ : sorted r l) (h₂ : ∀ b ∈ l, r a b) :
  sorted r (a :: l) :=
⟨h₁, h₂⟩

lemma eq_of_sorted_of_perm (tr : transitive r) (anti : anti_symmetric r) :
  ∀ {l₁ l₂ : list α}, l₁ ~ l₂ → sorted r l₁ → sorted r l₂ → l₁ = l₂
| []       l   h₁ h₂ h₃ := eq.symm $ eq_nil_of_perm_nil $ h₁
| l        []  h₁ h₂ h₃ := eq_nil_of_perm_nil $ h₁.symm
| (a::l₁)  l₂  h₁ h₂ h₃ :=
  have aux : ∀ {t}, l₂ = a::t → a::l₁ = l₂, from
    assume t, assume : l₂ = a::t,
    have l₁ ~ t,        by rewrite [this] at h₁; apply perm_cons_inv h₁,
    have sorted r l₁,   from h₂.left,
    have sorted r t,    by rewrite [‹l₂ = a::t›] at h₃; exact h₃.left,
    have l₁ = t,        from eq_of_sorted_of_perm ‹l₁ ~ t› ‹sorted r l₁› ‹sorted r t›,
    show a :: l₁ = l₂,  by rewrite [‹l₂ = a::t›, this],
  have   a ∈ l₂,        from mem_of_perm h₁ $ mem_cons_self _ _,
  let ⟨s, t, (e₁ : l₂ = s ++ (a::t))⟩ := mem_split this in
  begin
    cases s with b s,
    { have : l₂ = a::t, by exact e₁,
      exact aux this },
    { have e₁ : l₂ = b::(s++(a::t)), by exact e₁,
      have : b ∈ l₂,                begin rewrite e₁, apply mem_cons_self _ _ end,
      have hall₂ : ∀c∈s++(a::t), r b c,
        begin rw [e₁] at h₃, apply forall_mem_rel_of_sorted_cons r h₃ end,
      have : a ∈ s++(a::t),         from mem_append_right _ (mem_cons_self _ _),
      have : r b a,                 from hall₂ _ this,
      have : b ∈ a::l₁,             from mem_of_perm (perm.symm h₁) ‹b ∈ l₂›,
      have hall₁ : ∀b∈l₁, r a b,  from forall_mem_rel_of_sorted_cons r h₂,
      apply or.elim (eq_or_mem_of_mem_cons ‹b ∈ a::l₁›),
        assume : b = a,  begin rewrite this at e₁, exact aux e₁ end,
        assume : b ∈ l₁,
          have : r a b, from hall₁ _ this,
          have : b = a, from anti ‹r b a› ‹r a b›,
          begin rewrite this at e₁, exact aux e₁ end }
end

end sorted

/-
  sorting procedures
-/

section sort
universe variable uu
parameters {α : Type uu} (r : α → α → Prop) [decidable_rel r]
local infix `≼` : 50 := r

/- insertion sort -/

section insertion_sort

def ordered_insert (a : α) : list α → list α
| []       := [a]
| (b :: l) := if a ≼ b then a :: b :: l else b :: ordered_insert l

--@[simp] theorem ordered_insert_nil (a : α) : ordered_insert a [] = [a] := rfl

--@[simp] theorem ordered_insert_cons (a b : α) (l : list α) :
--  ordered_insert a (b :: l) = if a ≼ b then a :: (b :: l) else b :: ordered_insert a l :=
--rfl


def insertion_sort : list α → list α
| []       := []
| (b :: l) := ordered_insert b (insertion_sort l)

--attribute [simp] insertion_sort.equations.eqn_1 insertion_sort.equations.eqn_2

section correctness
parameter [deceqα : decidable_eq α]
include deceqα
open perm

theorem perm_ordered_insert (a) : ∀ l : list α, ordered_insert a l ~ a :: l
| []       := perm.refl _
| (b :: l) := by simp [ordered_insert]; by_cases a ≼ b; simp [h];
  exact (perm.skip _ (perm_ordered_insert l)).trans (perm.swap _ _ _)

theorem perm_insertion_sort : ∀ l : list α, insertion_sort l ~ l
| []       := perm.nil
| (b :: l) := by simp [insertion_sort]; exact
  (perm_ordered_insert _ _ _).trans (perm.skip b (perm_insertion_sort l))

section total_and_transitive
variables (totr : total r) (transr : transitive r)
include totr transr

theorem sorted_ordered_insert (a : α) : ∀ l, sorted r l → sorted r (ordered_insert a l)
| []       h := sorted_singleton r a
| (b :: l) h := begin
    simp [ordered_insert]; by_cases a ≼ b with h'; simp [h'],
    { rw [sorted], refine ⟨h, λ b' bm, _⟩,
      simp at bm, cases bm with be bm,
      { subst b', exact h' },
      { exact transr h' (h.right _ bm) } },
    { rw [sorted], refine ⟨sorted_ordered_insert l h.left, λ b' bm, _⟩,
      have bm := mem_of_perm (perm_ordered_insert _ _ _) bm,
      simp at bm, cases bm with be bm,
      { subst b', exact (totr _ _).resolve_left h' },
      { exact h.right _ bm } }
    end

theorem sorted_insertion_sort : ∀ l, sorted r (insertion_sort l)
| []       := sorted_nil r
| (a :: l) := sorted_ordered_insert totr transr a _ (sorted_insertion_sort l)

end total_and_transitive
end correctness
end insertion_sort

/- merge sort -/

section merge_sort

-- TODO(Jeremy): observation: if instead we write (a :: (split l).1, b :: (split l).2), the
-- equation compiler can't prove the third equation

def split : list α → list α × list α
| []            := ([], [])
| (a :: l) := let (l₁, l₂) := split l in (a :: l₂, l₁)
attribute [simp] split

theorem split_cons_of_eq (a : α) {l l₁ l₂ : list α} (h : split l = (l₁, l₂)) :
  split (a :: l) = (a :: l₂, l₁) :=
by rw [split, h]; refl

theorem length_split_le : ∀ {l l₁ l₂ : list α},
  split l = (l₁, l₂) → length l₁ ≤ length l ∧ length l₂ ≤ length l
| []     ._  ._  rfl := ⟨nat.le_refl 0, nat.le_refl 0⟩
| (a::l) l₁' l₂' h   := begin
  ginduction split l with e l₁ l₂,
  injection (split_cons_of_eq _ e).symm.trans h,
  subst l₁', subst l₂',
  cases length_split_le e with h₁ h₂,
  exact ⟨nat.succ_le_succ h₂, nat.le_succ_of_le h₁⟩
end

theorem length_split_lt {a b} {l l₁ l₂ : list α} (h : split (a::b::l) = (l₁, l₂)) :
  length l₁ < length (a::b::l) ∧ length l₂ < length (a::b::l) :=
begin
  ginduction split l with e l₁' l₂',
  injection (split_cons_of_eq _ (split_cons_of_eq _ e)).symm.trans h,
  subst l₁, subst l₂,
  cases length_split_le e with h₁ h₂,
  exact ⟨nat.succ_le_succ (nat.succ_le_succ h₁), nat.succ_le_succ (nat.succ_le_succ h₂)⟩
end

theorem perm_split : ∀ {l l₁ l₂ : list α}, split l = (l₁, l₂) → l ~ l₁ ++ l₂
| []     ._  ._  rfl := perm.refl _
| (a::l) l₁' l₂' h   := begin
  ginduction split l with e l₁ l₂,
  injection (split_cons_of_eq _ e).symm.trans h,
  subst l₁', subst l₂',
  exact perm.skip a ((perm_split e).trans perm.perm_app_comm),
end

def merge : list α → list α → list α
| []       l'        := l'
| l        []        := l
| (a :: l) (b :: l') := if a ≼ b then a :: merge l (b :: l') else b :: merge (a :: l) l'

include r
def merge_sort : list α → list α
| []        := []
| [a]       := [a]
| (a::b::l) := begin
  ginduction split (a::b::l) with e l₁ l₂,
  cases length_split_lt e with h₁ h₂,
  exact merge r (merge_sort l₁) (merge_sort l₂)
end
using_well_founded {
  rel_tac := λ_ _, `[exact ⟨_, inv_image.wf length nat.lt_wf⟩],
  dec_tac := tactic.assumption }

theorem merge_sort_cons_cons {a b} {l l₁ l₂ : list α}
  (h : split (a::b::l) = (l₁, l₂)) :
  merge_sort (a::b::l) = merge (merge_sort l₁) (merge_sort l₂) :=
begin
  simp [merge_sort, h], dsimp,
  have : ∀ (L : list α) h1, @@and.rec
    (λ a a (_ : length l₁ < length l + 1 + 1 ∧
      length l₂ < length l + 1 + 1), L) h1 h1 = L,
  { intros, cases h1, refl },
  apply this
end

section correctness
parameter [deceqα : decidable_eq α]
include deceqα

theorem perm_merge : ∀ (l l' : list α), merge l l' ~ l ++ l'
| []       []        := perm.nil
| []       (b :: l') := by simp [merge]
| (a :: l) []        := by simp [merge]
| (a :: l) (b :: l') := by simp [merge]; by_cases a ≼ b; simp [h];
  [exact perm.skip _ (perm_merge _ _),
   exact (perm.skip _ (perm_merge _ _)).trans
     (perm.trans (perm.swap _ _ _) (perm.skip _ (perm.perm_middle _ _ _)))]

theorem perm_merge_sort : ∀ l : list α, merge_sort l ~ l
| []        := perm.refl _
| [a]       := perm.refl _
| (a::b::l) := begin
  ginduction split (a::b::l) with e l₁ l₂,
  cases length_split_lt e with h₁ h₂,
  rw [merge_sort_cons_cons r e],
  apply (perm_merge r _ _).trans,
  exact (perm.perm_app (perm_merge_sort l₁) (perm_merge_sort l₂)).trans (perm_split e).symm
end
using_well_founded {
  rel_tac := λ_ _, `[exact ⟨_, inv_image.wf length nat.lt_wf⟩],
  dec_tac := tactic.assumption }

section total_and_transitive
variables (totr : total r) (transr : transitive r)
include totr transr

theorem sorted_merge : ∀ {l l' : list α}, sorted r l → sorted r l' → sorted r (merge l l')
| []       []        h₁ h₂ := trivial
| []       (b :: l') h₁ h₂ := by simp [merge]; exact h₂
| (a :: l) []        h₁ h₂ := by simp [merge]; exact h₁
| (a :: l) (b :: l') h₁ h₂ := begin
  simp [merge]; by_cases a ≼ b; simp [h],
  { refine ⟨sorted_merge h₁.left h₂, λ b' bm, _⟩,
    have bm := perm.mem_of_perm (perm_merge _ _ _) bm,
    simp at bm,
    cases bm with be bm,
    { subst b', assumption },
    cases bm with bl bl',
    { exact h₁.right _ bl },
    { exact transr h (h₂.right _ bl') } },
  { refine ⟨sorted_merge h₁ h₂.left, λ b' bm, _⟩,
    have bm := perm.mem_of_perm (perm_merge _ _ _) bm,
    simp at bm,
    have ba : b ≼ a := (totr _ _).resolve_left h,
    cases bm with be bm,
    { subst b', assumption },
    cases bm with bl bl',
    { exact transr ba (h₁.right _ bl) },
    { exact h₂.right _ bl' } }
end

theorem sorted_merge_sort : ∀ l : list α, sorted r (merge_sort l)
| []        := sorted_nil _
| [a]       := sorted_singleton _ _
| (a::b::l) := begin
  ginduction split (a::b::l) with e l₁ l₂,
  cases length_split_lt e with h₁ h₂,
  rw [merge_sort_cons_cons r e],
  exact sorted_merge r totr transr (sorted_merge_sort l₁) (sorted_merge_sort l₂)
end
using_well_founded {
  rel_tac := λ_ _, `[exact ⟨_, inv_image.wf length nat.lt_wf⟩],
  dec_tac := tactic.assumption }

end total_and_transitive
end correctness
end merge_sort
end sort

/- try them out! -/

--#eval insertion_sort (λ m n : ℕ, m ≤ n) [5, 27, 221, 95, 17, 43, 7, 2, 98, 567, 23, 12]

--#eval merge_sort     (λ m n : ℕ, m ≤ n) [5, 27, 221, 95, 17, 43, 7, 2, 98, 567, 23, 12]

end list
