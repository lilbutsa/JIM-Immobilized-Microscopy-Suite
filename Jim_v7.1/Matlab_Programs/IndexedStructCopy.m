function T = IndexedStructCopy(S, Condition, FieldList)
if nargin == 2
   FieldList = fieldnames(S);
end 
for iField = 1:numel(FieldList)
   Field    = FieldList{iField};
   T.(Field) = S.(Field)(Condition);
end
end