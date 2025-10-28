from django import forms

class NumberForm(forms.Form):
    a = forms.FloatField(label='Number a', required=True)
    b = forms.FloatField(label='Number b', required=True)
    c = forms.FloatField(label='Number c', required=True)
    d = forms.FloatField(label='Number d', required=True)
    e = forms.FloatField(label='Number e', required=True)